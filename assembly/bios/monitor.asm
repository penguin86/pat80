; Pat80 Memory Monitor
; @author Daniele Verducci
;
; Monitor commands (CMD $arg):
;   DMP $pos Dumps first 100 bytes of memory starting at $pos
;   SET $pos $val Replaces byte at $pos with $val
;   LOA $pos $val Loads all the incoming bytes in memory starting from $pos
;   RUN $pos Starts executing code from $pos

; CONSTANTS
; All monitor commands are 3 chars long.
MON_COMMAND_DMP: DB "DMP",0  ; null terminated strings
MON_COMMAND_DMP: DB "SET",0
MON_COMMAND_DMP: DB "LOA",0
MON_COMMAND_DMP: DB "RUN",0

Monitor_main:
    ; Read from command line
    
    ret

; Parses a command
; TODO: This is not very efficient, should be implemented as a tree, but for few commands is ok...
; return A The interpreted command, or 0 if not found
monitor_parse:
    ret
