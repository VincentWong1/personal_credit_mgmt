"""身份证号校验与性别提取工具。"""

# 加权因子
WEIGHTS = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
CHECK_CODES = "10X98765432"


def validate_id_card(id_card: str) -> bool:
    """校验 18 位身份证号是否合法。"""
    if len(id_card) != 18:
        return False
    body = id_card[:17]
    if not body.isdigit():
        return False
    check = id_card[17].upper()
    total = sum(int(body[i]) * WEIGHTS[i] for i in range(17))
    expected = CHECK_CODES[total % 11]
    return check == expected


def extract_gender(id_card: str) -> str:
    """从身份证号提取性别：倒数第二位奇数为男，偶数为女。"""
    return "male" if int(id_card[16]) % 2 == 1 else "female"
