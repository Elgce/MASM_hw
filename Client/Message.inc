;�������ṹ��
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
MSG_HEAD		struct
	dwCmdId		dw	?
	dwLength	dd	?
MSG_HEAD		ends

;��Ӧ���ݰ���������-���ͻ��ˣ�
MSG_LOGIN_RESP	struct
	dbResult	db	?	;��½�����0=�ɹ���1=ʧ��
MSG_LOGIN_RESP	ends

;������Ϣ �ͻ���-��������
MSG_UP			struct
	dwLength	dd	?
	szContent	db	256 dup(?)
	szSender	db	12 dup(?)
MSG_UP			ends

;������Ϣ ������-���ͻ���
MSG_DOWN		struct
  szSender		db	12 dup (?)	
  dwLength		dd	?		
  szContent		db	256 dup (?)	
MSG_DOWN		ends

;��Ϣ����
MSG_STRUCT		struct
  MsgHead		MSG_HEAD <>
  union
    LoginResp	MSG_LOGIN_RESP <>
    MsgUp		MSG_UP <>
    MsgDown		MSG_DOWN <>
  ends
MSG_STRUCT		ends
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>