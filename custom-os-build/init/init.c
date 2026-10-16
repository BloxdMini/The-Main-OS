#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

static void log_msg(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);
}

static void ensure_dir(const char *path, mode_t mode) {
    if (mkdir(path, mode) == -1 && errno != EEXIST) {
        log_msg("failed to create %s: %s\n", path, strerror(errno));
        _exit(1);
    }
}

static void mount_fs(const char *source, const char *target, const char *fstype, unsigned long flags, const char *data) {
    if (mount(source, target, fstype, flags, data) == -1 && errno != EBUSY) {
        log_msg("mount %s (%s) failed: %s\n", target, fstype, strerror(errno));
        _exit(1);
    }
}

static pid_t spawn_process(const char *path, char *const argv[]) {
    pid_t pid = fork();
    if (pid == 0) {
        setsid();
        execv(path, argv);
        log_msg("failed to exec %s: %s\n", path, strerror(errno));
        _exit(127);
    }
    if (pid < 0) {
        log_msg("fork failed: %s\n", strerror(errno));
        _exit(1);
    }
    return pid;
}

static pid_t start_display_manager(void) {
    if (access("/usr/sbin/lightdm", X_OK) == 0) {
        char *const argv[] = {"lightdm", NULL};
        return spawn_process("/usr/sbin/lightdm", argv);
    }
    if (access("/usr/bin/xdm", X_OK) == 0) {
        char *const argv[] = {"xdm", NULL};
        return spawn_process("/usr/bin/xdm", argv);
    }
    if (access("/bin/bash", X_OK) == 0) {
        char *const argv[] = {"bash", "-l", NULL};
        return spawn_process("/bin/bash", argv);
    }
    char *const argv[] = {"sh", NULL};
    return spawn_process("/bin/sh", argv);
}

static void setup_console(void) {
    int fd = open("/dev/console", O_RDWR | O_NOCTTY);
    if (fd >= 0) {
        dup2(fd, STDIN_FILENO);
        dup2(fd, STDOUT_FILENO);
        dup2(fd, STDERR_FILENO);
        close(fd);
    }
}

int main(void) {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = SIG_IGN;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGCHLD, &sa, NULL);

    ensure_dir("/run", 0755);
    ensure_dir("/tmp", 1777);
    ensure_dir("/proc", 0755);
    ensure_dir("/sys", 0755);
    ensure_dir("/dev", 0755);
    ensure_dir("/dev/pts", 0755);

    mount_fs("proc", "/proc", "proc", 0, NULL);
    mount_fs("sysfs", "/sys", "sysfs", 0, NULL);
    mount_fs("tmpfs", "/run", "tmpfs", 0, NULL);
    mount_fs("tmpfs", "/tmp", "tmpfs", 0, NULL);
    mount_fs("devtmpfs", "/dev", "devtmpfs", 0, NULL);
    mount_fs("devpts", "/dev/pts", "devpts", 0, NULL);

    setup_console();

    pid_t child = start_display_manager();
    if (child <= 0) {
        log_msg("no boot target available\n");
        _exit(1);
    }

    for (;;) {
        int status = 0;
        pid_t waited = waitpid(-1, &status, 0);
        if (waited < 0) {
            if (errno == EINTR) {
                continue;
            }
            log_msg("waitpid failed: %s\n", strerror(errno));
            break;
        }

        if (WIFEXITED(status) || WIFSIGNALED(status)) {
            usleep(250000);
            child = start_display_manager();
            if (child <= 0) {
                break;
            }
        }
    }

    return 0;
}
