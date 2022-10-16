;server
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
includelib      msvcrt.lib
printf          PROTO C :ptr sbyte, :VARARG
ICO_MAIN	equ	1000
DLG_MAIN	equ	2000
IDC_COUNT	equ	2001
TCP_PORT	equ	9999



;客户端会话消息
SESSION	struct
	szUserName	db 12 dup(?) ;用户名
	dwMessageId	dd	?	;已经下发的消息编号
	dwLastTime	dd	?	;链路最近一次活动时间
SESSION	ends


.data
dwSequence	dd	1
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
include	Message.inc
		assume esi:ptr MSG_STRUCT,edi:ptr SESSION

_WaitData	proc	_hSocket,_dwTime
		local	@stFdSet:fd_set,@stTimeval:timeval

		mov	@stFdSet.fd_count,1
		push	_hSocket
		pop	@stFdSet.fd_array
		push	_dwTime
		pop	@stTimeval.tv_usec
		mov	@stTimeval.tv_sec,0
		invoke	select,0,addr @stFdSet,NULL,NULL,addr @stTimeval
		ret

_WaitData	endp
;接受数据
_RecvData	proc	_hSocket,_lpData,_dwSize
		local	@dwStartTime

		mov	esi,_lpData
		mov	ebx,_dwSize
		invoke	GetTickCount
		mov	@dwStartTime,eax
		@@:
		invoke	GetTickCount			;查看是否超时
		sub	eax,@dwStartTime
		cmp	eax,10 * 1000
		jge	_Err
		invoke	_WaitData,_hSocket,100*1000	;等待数据100ms
		cmp	eax,SOCKET_ERROR
		jz	_Err
		or	eax,eax
		jz	@B
		invoke	recv,_hSocket,esi,ebx,0
		.if	(eax == SOCKET_ERROR) || ! eax
_Err:
			xor	eax,eax
			inc	eax
			ret
		.endif
		.if	eax <	ebx
			add	esi,eax
			sub	ebx,eax
			jmp	@B
		.endif
		xor	eax,eax
		ret

_RecvData	endp
; 接收一个符合规范的数据包
_RecvPacket	proc	_hSocket,_lpBuffer,_dwSize
		local	@dwReturn

		pushad
		mov	@dwReturn,TRUE
		mov	esi,_lpBuffer
		assume	esi:ptr MSG_STRUCT
		invoke	_RecvData,_hSocket,esi,sizeof MSG_HEAD
		or	eax,eax
		jnz	_Ret
		mov	ecx,[esi].MsgHead.dwLength
		cmp	ecx,sizeof MSG_HEAD
		jb	_Ret
		cmp	ecx,_dwSize
		ja	_Ret
		sub	ecx,sizeof MSG_HEAD
		add	esi,sizeof MSG_HEAD
		.if	ecx
			invoke	_RecvData,_hSocket,esi,ecx
		.else
			xor	eax,eax
		.endif
		mov	@dwReturn,eax
_Ret:
		popad
		assume	esi:nothing
		mov	eax,@dwReturn
		ret

_RecvPacket	endp


; 通讯服务线程：每个客户端登录的连接将产生一个线程
_ServiceThread	proc	_hSocket
		local @szBuffer[512]:byte,@stSession:SESSION
		pushad
		inc	dwThreadCounter
		invoke	SetDlgItemInt,hWinMain,IDC_NUM,dwThreadCounter,FALSE
		
		lea	esi,@szBuffer
		lea edi,@stSession
		invoke	RtlZeroMemory,edi,sizeof @stSession
		mov eax,dwSequence
		mov [edi].dwMessageId,eax
		invoke	_RecvPacket,_hSocket,esi,sizeof @szBuffer
		assume	esi:ptr MSG_STRUCT
		invoke SendDlgItemMessage, hWinMain, IDC_LIST_CLIENTS, LB_ADDSTRING, 0, addr [esi].MsgUp.szSender

		.while	! (dwFlag & F_STOP)
		;消息循环
		.endw
		invoke	closesocket,_hSocket
		dec	dwThreadCounter
		invoke	SetDlgItemInt,hWinMain,IDC_NUM,dwThreadCounter,FALSE
		popad
		ret

_ServiceThread	endp
	assume esi:nothing,edi:nothing
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