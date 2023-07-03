import requests
import json

# URL
url = "http://127.0.0.1:5000/api/request"

# 챗봇 API
data = {
    # recommend : 해수욕장 추천, guide : 이용안내
    'category': 'recommend',  # 카테고리 정보
    'user_request': '20대 남자들이 갈 해수욕장 추천해줘'  # 사용자 요구사항 텍스트
}
# # 해파리 호출 API
# data = {
#     # obs_code = [송정 : 'TW_0092', 임랑 : 'TW_0090', 해운대 : 'TW_0062']
#     'obs_code': 'TW_0090',  # 카테고리 정보
# }


# POST 요청 보내기
response = requests.post(url, json=data)

if response.status_code == 200:
    result = response.json()
    message = result.get('message')
    print('응답:', message)
else:
    print('API 요청 실패:', response.status_code)
