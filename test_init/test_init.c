#include <linux/reboot.h>
#include <sys/syscall.h>
#include <sys/reboot.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <stdbool.h>

int main() {
    /* For now, let's immediately shutdown. */
    int ret = reboot(LINUX_REBOOT_CMD_HALT);
    if (!ret) {
        perror("reboot");
    }

    /* Since we're an init process, we should stay
     * running.
     */
    while (true) { /* spin */ }
}
