.386
.model flat, stdcall
option casemap:none

includelib      msvcrt.lib
printf          PROTO C :ptr sbyte, :VARARG
scanf           PROTO C :ptr sbyte, :VARARG

.data
nameMsg			byte    "姓名：贲清炜", 0ah, 0dh, 0
numMsg			byte    "学号：2020013061", 0ah, 0dh, 0  
classMsg        byte    "班级：未央-软件01",0ah, 0ah, 0; 0ah 0dh是回车换行
pauseMsg        byte    "按回车退出", 0

.code
start PROC
                invoke  printf, offset nameMsg  ; 调用printf
                invoke  printf, offset numMsg
                invoke  printf, offset classMsg
                invoke  scanf, offset pauseMsg
                ret
start ENDP
end				start

