org 0xA000
include '../../os/abi-generated.asm'

STRING: DB "Hello",0
ld bc, STRING
call Sys_Print
jp 0