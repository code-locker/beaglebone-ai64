#include <stdio.h>

/* Userspace part: reads the device created by kernel/tmpl_drv.c, if loaded. */
#define DEV "/dev/tmpl_drv"

int main(void)
{
    char buf[128];
    size_t n;
    FILE *f;

    printf("Hello from BeagleBone AI-64 (aarch64 / Cortex-A72)\n");

    f = fopen(DEV, "r");
    if (!f) {
        perror(DEV);
        return 1;
    }
    n = fread(buf, 1, sizeof(buf) - 1, f);
    buf[n] = '\0';
    fclose(f);
    printf("%s: %s", DEV, buf);
    return 0;
}
