;client
.386
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
includelib user32.lib
includelib kernel32.lib
include		wsock32.inc
includelib	wsock32.lib
includelib      msvcrt.lib
printf          PROTO C :ptr sbyte, :VARARG
include Message.inc

.data
hInstance	DWORD	?
massage		DWORD	256 dup(?)
user1       BYTE	'syz',0
user2       BYTE	'bqw',0
user3       BYTE	'lzy',0
user        BYTE	8 dup(?)
user_ms		DWORD	256 dup(?)
@line		BYTE	'------', 0
empty_ms	DWORD	256 dup(?)

szServer	BYTE	16 dup(?)
szUserName	db		12 dup(?)
hSocket		DWORD	?
dwSendBufSize	dd	?
dwRecvBufSize	dd	?

szSendMsg	MSG_STRUCT	10 dup (<>)

.const
IDD_MAIN					=			101
IDC_EDIT					=			1001
IDC_LIST_FRIENDS			=           1002
IDC_EDIT_MASSAGE			=           1003
IDC_BUTTON_SEND				=           1004
IDC_STATIC_FRIENDNAME       =		    1005
IDC_LOGOUT                  =           1014
IDC_LOGIN                   =           1015
IDC_NAME                    =           1016
IDC_IP                      =           1017
IDC_EDIT_IP                 =           1018
IDC_EDIT_NAME               =           1019
IDC_BUTTON_ADD              =           1020
TCP_PORT					=			9999



.code
;工作线程
_WorkThread	proc	_lParam
		local	@stSin:sockaddr_in

		invoke	RtlZeroMemory,addr @stSin,sizeof @stSin
		invoke	inet_addr,addr szServer
		mov	@stSin.sin_addr,eax
		mov	@stSin.sin_family,AF_INET
		invoke	htons,TCP_PORT
		mov	@stSin.sin_port,ax
		invoke	socket,AF_INET,SOCK_STREAM,0
		mov	hSocket,eax
		invoke	connect,hSocket,addr @stSin,sizeof @stSin

		.while	hSocket

		.endw

		ret
_WorkThread	endp

; 发送消息
_SendData	proc	_lpData,_dwSize
	pushad
	;发送内容加载至缓冲区尾部
	mov esi, _lpData
	mov ecx, _dwSize
	.if esi & ecx
		push	ecx
		mov	edi,offset szSendMsg
		add	edi,dwSendBufSize
		cld
		rep	movsb
		pop	ecx
		add	dwSendBufSize,ecx
	.endif
	;发送到缓冲区
	mov esi,offset szSendMsg
	mov ebx,dwSendBufSize
	invoke send,hSocket,esi,ebx,0
	ret
_SendData	endp

;连接服务器
_Connect	proc
		local	@stSin:sockaddr_in
		local	@szBuffer[512]:byte
		pushad
		
		;创建Socket
		invoke	RtlZeroMemory,addr @stSin, sizeof @stSin
		invoke	inet_addr,addr szServer
		mov	@stSin.sin_addr,eax
		mov	@stSin.sin_family,AF_INET
		invoke	htons,TCP_PORT
		mov	@stSin.sin_port,ax
		invoke	socket,AF_INET,SOCK_STREAM,0
		mov	hSocket,eax
		;连接服务器，这里没有设置成非阻塞模式
		invoke	connect,hSocket,addr @stSin,sizeof @stSin
		ret
_Connect	endp


;主程序函数
MainProc proc,
	hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
	local	@stWsa:WSADATA,@stMsg:MSG_STRUCT
	mov eax,uMsg
	.if eax == WM_CLOSE
		invoke EndDialog,hWnd,0
	.elseif eax == WM_INITDIALOG
		invoke WSAStartup, 101h, addr @stWsa
		; TODO:此处改为循环
		invoke SendDlgItemMessage, hWnd, IDC_LIST_FRIENDS, LB_ADDSTRING, 0, addr user1
		invoke SendDlgItemMessage, hWnd, IDC_LIST_FRIENDS, LB_ADDSTRING, 0, addr user2
		invoke SendDlgItemMessage, hWnd, IDC_LIST_FRIENDS, LB_ADDSTRING, 0, addr user3
	.elseif eax == WM_COMMAND
		mov eax,wParam
		.if ax == IDC_BUTTON_SEND
		; TODO: 完成发送和显示的逻辑
			;通过massage储存信息
			invoke GetDlgItemText,hWnd,IDC_EDIT,addr massage,sizeof massage
			.if massage
				invoke SetDlgItemText,hWnd,IDC_EDIT,NULL
				;串联出最终需要的消息内容到user_ms
				cld
				mov ecx, LENGTHOF empty_ms
				mov esi, OFFSET empty_ms
				mov edi, OFFSET user_ms
				rep movsd
				; TODO： 接口获取时间字符串，连接到user_ms
				invoke lstrcat, addr user_ms, addr @line
				invoke lstrcat, addr user_ms, addr user
				invoke lstrcat, addr user_ms, addr @line ; 拼接用户名字
				invoke SendDlgItemMessage,hWnd,IDC_EDIT_MASSAGE, LB_ADDSTRING, 0,addr user_ms
				invoke SendDlgItemMessage,hWnd,IDC_EDIT_MASSAGE, LB_ADDSTRING, 0,addr massage
				invoke lstrcpy,addr @stMsg.MsgUp.szContent,addr massage
				invoke lstrcpy,addr @stMsg.MsgUp.szSender,addr szUserName
				invoke lstrlen,addr @stMsg.MsgUp.szContent
				inc eax
				mov @stMsg.MsgUp.dwLength,eax
				add eax,sizeof MSG_HEAD+MSG_UP.szContent+MSG_UP.szSender
				mov	@stMsg.MsgHead.dwLength, eax
				invoke _SendData,addr @stMsg,@stMsg.MsgHead.dwLength
			.endif
		.elseif ax == IDC_LIST_FRIENDS
		; TODO: 根据选中的用户显示聊天内容
			invoke SendDlgItemMessage, hWnd, IDC_LIST_FRIENDS, LB_GETCURSEL, 0, 0
			invoke SendDlgItemMessage, hWnd, IDC_LIST_FRIENDS, LB_GETTEXT, ax, addr user
			invoke SetDlgItemText,hWnd,IDC_STATIC_FRIENDNAME,addr user
		.elseif	ax == IDC_LOGIN
			;invoke	GetDlgItemText,hWnd,IDC_EDIT_IP,addr szServer,sizeof szServer
			;push	ecx
			;invoke	CreateThread,NULL,0,offset _WorkThread,0,NULL,esp
			;pop	ecx
			;invoke	CloseHandle,eax
			invoke	GetDlgItemText,hWnd,IDC_EDIT_IP,addr szServer,sizeof szServer
			invoke	GetDlgItemText,hWnd,IDC_EDIT_NAME,addr szUserName, sizeof szUserName
			invoke _Connect
			invoke lstrcpy,addr @stMsg.MsgUp.szContent,addr massage
			invoke lstrcpy,addr @stMsg.MsgUp.szSender,addr szUserName
			invoke lstrlen,addr @stMsg.MsgUp.szContent
			inc eax
			mov @stMsg.MsgUp.dwLength,eax
			add eax,sizeof MSG_HEAD+MSG_UP.szContent+MSG_UP.szSender
			mov	@stMsg.MsgHead.dwLength, eax
			invoke _SendData,addr @stMsg,@stMsg.MsgHead.dwLength
		.endif
	.else
		mov eax,FALSE
		ret
	.endif
	mov eax,TRUE
	ret
MainProc endp

start:
	invoke GetModuleHandle,NULL
	mov hInstance,eax
	invoke DialogBoxParam,hInstance,IDD_MAIN,NULL, addr MainProc,NULL
	invoke ExitProcess,eax

end start