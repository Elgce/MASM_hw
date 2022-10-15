.386
.model flat,stdcall
option casemap:none

include		windows.inc
include		user32.inc
includelib	user32.lib
include		kernel32.inc
includelib	kernel32.lib
include		wsock32.inc
includelib	wsock32.lib
ICO_MAIN	equ	1000
DLG_MAIN	equ	2000
IDC_COUNT	equ	2001
TCP_PORT	equ	9999

.data
hInstance	dd	?
hWinMain	dd	?
hListenSocket	dd	?
dwThreadCounter	dd	?
dwFlag		dd	?
F_STOP		equ	0001h

user1       BYTE	'syz',0
user2       BYTE	'bqw',0
user3       BYTE	'lzy',0
user        BYTE	8 dup(?)
users		DWORD	100 dup(?)

.const
IDD_MAIN                  =          101
IDC_EDIT                  =          1001
IDC_LIST_CLIENTS          =          1002
IDC_IP                    =          1003
IDC_EDIT_IP               =          1004
IDC_NUM					  =			 1005
IDC_SERVER_INFO           =          1006
IDC_STATIC_NUM            =          1007
szErrBind	db	'无法绑定到TCP端口9999，请检查是否有其它程序在使用!',0

.code
; 通讯服务线程：每个客户端登录的连接将产生一个线程
_ServiceThread	proc	_hSocket
		inc	dwThreadCounter
		invoke	SetDlgItemInt,hWinMain,IDC_NUM,dwThreadCounter,FALSE
		.while	! (dwFlag & F_STOP)
			;在这里死循环
		.endw
		invoke	closesocket,_hSocket
		dec	dwThreadCounter
		invoke	SetDlgItemInt,hWinMain,IDC_NUM,dwThreadCounter,FALSE
		ret

_ServiceThread	endp

; 监听线程
_ListenThread	proc	_lParam
		local	@stSin:sockaddr_in

		invoke	socket,AF_INET,SOCK_STREAM,0
		mov	hListenSocket,eax

		invoke	RtlZeroMemory,addr @stSin,sizeof @stSin
		invoke	htons,TCP_PORT
		mov	@stSin.sin_port,ax
		mov	@stSin.sin_family,AF_INET
		mov	@stSin.sin_addr,INADDR_ANY
		invoke	bind,hListenSocket,addr @stSin,sizeof @stSin
		.if	eax
			invoke	MessageBox,hWinMain,addr szErrBind,\
				NULL,MB_OK or MB_ICONSTOP
			invoke	ExitProcess,NULL
			ret
		.endif

; 开始监听，等待连接进入并为每个连接创建一个线程
		invoke	listen,hListenSocket,5
		.while	TRUE
			invoke	accept,hListenSocket,NULL,0
			.break	.if eax == INVALID_SOCKET
			push	ecx
			invoke	CreateThread,NULL,0,offset _ServiceThread,eax,NULL,esp
			pop	ecx
			invoke	CloseHandle,eax
		.endw
		invoke	closesocket,hListenSocket
		ret

_ListenThread	endp


; 主窗口程序
_ProcDlgMain	proc	uses ebx edi esi hWnd,wMsg,wParam,lParam
		local	@stWsa:WSADATA

		mov	eax,wMsg

		.if	eax ==	WM_INITDIALOG
			push	hWnd
			pop	hWinMain
			invoke	LoadIcon,hInstance,ICO_MAIN
			invoke	SendMessage,hWnd,WM_SETICON,ICON_BIG,eax
			invoke	WSAStartup,101h,addr @stWsa
			invoke SendDlgItemMessage, hWnd, IDC_LIST_CLIENTS, LB_ADDSTRING, 0, addr user1
			invoke SendDlgItemMessage, hWnd, IDC_LIST_CLIENTS, LB_ADDSTRING, 0, addr user2
			invoke SendDlgItemMessage, hWnd, IDC_LIST_CLIENTS, LB_ADDSTRING, 0, addr user3
		
			push	ecx
			invoke	CreateThread,NULL,0,offset _ListenThread,0,NULL,esp
			pop	ecx
			invoke	CloseHandle,eax

		.elseif	eax ==	WM_CLOSE
			invoke	closesocket,hListenSocket
			or	dwFlag,F_STOP
			.while	dwThreadCounter
			.endw
			invoke	WSACleanup
			invoke	EndDialog,hWinMain,NULL

		.else
			mov	eax,FALSE
			ret
		.endif
		mov	eax,TRUE
		ret

_ProcDlgMain	endp

start:
		invoke	GetModuleHandle,NULL
		mov	hInstance,eax
		invoke	DialogBoxParam,hInstance,IDD_MAIN,NULL, addr _ProcDlgMain,NULL
		invoke	ExitProcess,NULL

end start