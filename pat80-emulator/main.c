#include <stdio.h>
#include "z80/z80.h"

/*
 * The intercept function is invoked on each and every CPU instruction. It
 * quits the simulation when the PC register reaches address #0005 by changing
 * the virtual CPU status.
 */
static void intercept(void *ctx)
{
    z80 *cpu = ctx;
    if (PC == 5) {
        puts("\nReached address: 5, terminating the simulation...");
        cpu->status = 1;
    }
}

int main(int argc, char *argv[])
{
    /*
     * Instantiate the CPU, activate the debug mode, set the intercept
     * function and run the virtual CPU until the termination criteria
     * set by the intercept function, if any, are met.
     */
    z80 *cpu = z80_new();
    cpu->debug = 1;

    // TODO: Copy rom to first 32k CPU memory
    _RamWrite(0x03, 0x76);  // As an example, here is how to set HALT at posizion 0x03. Use a loop to copy memory from a PAT80 OS rom file.

    z80_set_intercept(cpu, cpu, intercept);
    z80_run(cpu);
    z80_destroy(cpu);
}
