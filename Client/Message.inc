;聊天段落结构体
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
MSG_HEAD		struct
	dwCmdId		dw	?
	dwLength	dd	?
MSG_HEAD		ends

;回应数据包（服务器-》客户端）
MSG_LOGIN_RESP	struct
	dbResult	db	?	;登陆结果：0=成功，1=失败
MSG_LOGIN_RESP	ends

;聊天消息 客户端-》服务器
MSG_UP			struct
	dwLength	dd	?
	szContent	db	256 dup(?)
	szSender	db	12 dup(?)
MSG_UP			ends

;聊天消息 服务器-》客户端
MSG_DOWN		struct
  szSender		db	12 dup (?)	
  dwLength		dd	?		
  szContent		db	256 dup (?)	
MSG_DOWN		ends

;消息整合
MSG_STRUCT		struct
  MsgHead		MSG_HEAD <>
  union
    LoginResp	MSG_LOGIN_RESP <>
    MsgUp		MSG_UP <>
    MsgDown		MSG_DOWN <>
  ends
MSG_STRUCT		ends
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>