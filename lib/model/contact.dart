// 联系人信息响应
class ContactInfoRes {
    String contactId;
    String contactName;
    int contactStatus;
    int contactType;

    ContactInfoRes({
        required this.contactId,
        required this.contactName,
        required this.contactStatus,
        required this.contactType,
    });

    factory ContactInfoRes.fromJson(Map<String, dynamic> json) => ContactInfoRes(
        contactId: json["contactId"],
        contactName: json["contactName"],
        contactStatus: json["contactStatus"],
        contactType: json["contactType"],
    );

    Map<String, dynamic> toJson() => {
        "contactId": contactId,
        "contactName": contactName,
        "contactStatus": contactStatus,
        "contactType": contactType,
    };
}