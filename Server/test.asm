.386
.model flat, stdcall
option casemap:none

includelib      msvcrt.lib
printf          PROTO C :ptr sbyte, :VARARG
scanf           PROTO C :ptr sbyte, :VARARG

.data
nameMsg			byte    "�����������", 0ah, 0dh, 0
numMsg			byte    "ѧ�ţ�2020013061", 0ah, 0dh, 0  
classMsg        byte    "�༶��δ��-���01",0ah, 0ah, 0; 0ah 0dh�ǻس�����
pauseMsg        byte    "���س��˳�", 0

.code
start PROC
                invoke  printf, offset nameMsg  ; ����printf
                invoke  printf, offset numMsg
                invoke  printf, offset classMsg
                invoke  scanf, offset pauseMsg
                ret
start ENDP
end				start

