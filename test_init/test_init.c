#include <linux/reboot.h>
#include <sys/syscall.h>
#include <sys/reboot.h>
#include <unistd.h>

int main() {
    /* For now, let's immediately shutdown. */
    reboot(LINUX_REBOOT_CMD_HALT);
}
