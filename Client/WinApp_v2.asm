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

szServer	BYTE	16 dup (?)
hSocket		DWORD	?

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
;主程序函数
MainProc proc,
	hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
	local	@stWsa:WSADATA
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
			invoke GetDlgItemText,hWnd,IDC_EDIT,addr massage,sizeof massage
			invoke SetDlgItemText,hWnd,IDC_EDIT,NULL
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
		.elseif ax == IDC_LIST_FRIENDS
		; TODO: 根据选中的用户显示聊天内容
			invoke SendDlgItemMessage, hWnd, IDC_LIST_FRIENDS, LB_GETCURSEL, 0, 0
			invoke SendDlgItemMessage, hWnd, IDC_LIST_FRIENDS, LB_GETTEXT, ax, addr user
			invoke SetDlgItemText,hWnd,IDC_STATIC_FRIENDNAME,addr user
		.elseif	ax == IDC_LOGIN
			invoke	GetDlgItemText,hWnd,IDC_EDIT_IP,addr szServer,sizeof szServer
			push	ecx
			invoke	CreateThread,NULL,0,offset _WorkThread,0,NULL,esp
			pop	ecx
			invoke	CloseHandle,eax
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