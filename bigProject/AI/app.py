from flask import Flask, request, jsonify, abort, render_template
import pandas as pd
import numpy as np
import joblib
from gensim.models import Word2Vec
import requests
from datetime import datetime, timedelta
from hanspell import spell_checker
import pytz

app = Flask(__name__)

# 모델 로드
guide_model = joblib.load('guide_model_rf.pkl')
guide_wv_model = joblib.load('guide_wv_model.pkl')
recommend_model = joblib.load('recommend_model_rf.pkl')
recommend_wv_model = joblib.load('recommend_wv_model.pkl')

jfish_model = joblib.load('jfish_et1_model.pkl')
# jfish_model = joblib.load('jfish_xgb1_model.pkl')

model = None
wv_model = None

@app.route('/api/request', methods=['POST'])
def process_request():
    global wv_model, model
    
    # 요청 받기
    request_data = request.get_json()
    category = request_data.get('category')
    user_request = request_data.get('user_request')
    
    if category == 'guide':
        model = guide_model
        wv_model = guide_wv_model
    elif category == 'recommend':
        model = recommend_model
        wv_model = recommend_wv_model
        
    # 맞춤법 검사
    user_request = spell_checker.check(user_request)
    user_request = user_request.checked

        
    # 요청 처리하기
    category_result = pipeline(user_request)
    
    # 일단은 해수욕장만 했음
    category_list = {
    'baby': wave_api,
    'young': wave_api,
    'mid': sea_status,
    'old' : sea_status,
    'solo' : rip_api,
    'login' : guide_list,
    'join' : guide_list,
    'photo_upload' : guide_list,
    'photo_search' : guide_list,
    'photo_change' : guide_list,
    'photo_del' : guide_list,
    'food_upload' : guide_list,
    'food_search' : guide_list,
    'food_change' : guide_list,
    'food_del' : guide_list,
    'service' : guide_list
    }
    
    if category_result in category_list:
        answer = category_list[category_result](category_result)
    else:
        print('카테고리 분류 실패')
    
    # 요청 처리 끝 -> 함수로 최대한 깔끔하게 해보기, 일단 api가져와서 대사하는건 나중에 하고 분류 잘 하는지 먼저 하기
    
    # 요청 처리 후 응답 반환
    response = {
        'message': f'{answer}'
    }
    return jsonify(response)

    
# 함수화
def get_sent_embedding(model, embedding_size, tokenized_words):
    feature_vec = np.zeros((embedding_size,), dtype="float32")
    n_words = 0
    for word in tokenized_words:
        if word in model.wv.key_to_index:
            n_words += 1
            # 임베딩 벡터에 해당 단어의 벡터를 더함
            feature_vec = np.add(feature_vec, model.wv[word])
    # 단어 개수가 0보다 큰 경우 벡터를 단어 개수로 나눠줌 (평균 임베딩 벡터 계산)
    if (n_words > 0):
        feature_vec = np.divide(feature_vec, n_words)
    return feature_vec

def get_dataset(sentences, model, num_features):
    dataset = list()

    # 각 문장을 벡터화해서 리스트에 저장
    for sent in sentences:
        dataset.append(get_sent_embedding(model, num_features, sent))

    # 리스트를 numpy 배열로 변환하여 반환
    sent_embedding_vectors = np.stack(dataset)

    return sent_embedding_vectors

def pipeline(user_request):
    from kiwipiepy import Kiwi
    kiwi = Kiwi()
    sentence = kiwi.tokenize(user_request)
    sentence_token = []
    for s in sentence:
        if s[1] in ['NNG', 'NNP', 'NNB', 'NR', 'NP', 'VV', 'VA', 'VX', 'VCP', 'VCN', 'JKS', 'JKC', 'JKG', 'JKO', 'JKB', 'JKV', 'JKQ', 'JX', 'JC' 'SN']:
            sentence_token.append(s[0])
    
    # 리스트를 numpy 배열로 변환
    sentence_token = np.array(sentence_token).tolist()
    sentence_token_vc = get_dataset([sentence_token], wv_model, 250)
    
    # # 모델로 예측하기
    # category = model.predict(sentence_token_vc)[0]
    
    # 예측 확률
    pred = model.predict(sentence_token_vc)[0]
    return pred

# 해수욕장 파고
def wave_api(text):
    from datetime import datetime, timedelta
    import pytz
    import requests

    # 인증키
    service_key = '4NK/rglt3c7VdkaTYoRPug=='

    # 가져올 해수욕장 코드 임랑, 송정, 해운대
    obs_code = ['TW_0092', 'TW_0090', 'TW_0062']
    obs_ko = ['임랑 해수욕장', '송정 해수욕장', '해운대 해수욕장']

    wave_list = []

    # 현재 시간을 UTC로 설정
    current_datetime = datetime.now(pytz.utc)

    # 한국 시간대로 변환
    korean_tz = pytz.timezone('Asia/Seoul')
    current_datetime = current_datetime.astimezone(korean_tz)
    search_date = current_datetime.strftime("%Y%m%d")
    
    for i in range(len(obs_code)):
        
        url = f"http://www.khoa.go.kr/api/oceangrid/obsWaveHight/search.do?ServiceKey={service_key}&ObsCode={obs_code[i]}&Date={search_date}&ResultType=json"
        response = requests.get(url)
        data = response.json()

        # 필요 항목 추출
        item_list = data['result']['data']
        last_wave_data = item_list[-1]['wave_height']
        wave_list.append(last_wave_data)

    float_wave_list = [float(value) for value in wave_list]
    max_index = float_wave_list.index(max(float_wave_list))
    min_index = float_wave_list.index(min(float_wave_list))

    if text == 'young':
        return f'입력하신 구성원에 맞는 추천 해수욕장은 파도의 높이가 {wave_list[max_index]}로 높은 {obs_ko[max_index]}을 추천드립니다.'
    elif text == 'baby':
        return f'입력하신 구성원에 맞는 추천 해수욕장은 파도의 높이가 {wave_list[min_index]}로 낮은 안전한 {obs_ko[min_index]}을 추천드립니다.'
    elif text == 'status':
        return f'파도의 높이가 {wave_list[min_index]}로 낮은 안전한 {obs_ko[min_index]}을 추천드립니다.'
    
# 이안류 제일 낮은 해수욕
def rip_api(text):
    from datetime import datetime, timedelta
    import pytz
    import requests

    # 인증키
    service_key = '4NK/rglt3c7VdkaTYoRPug=='

    # 가져올 해수욕장 코드 임랑, 송정, 해운대
    obs_code = ['IMRANG', 'SONGJUNG', 'HAE']
    obs_ko = ['임랑 해수욕장', '송정 해수욕장', '해운대 해수욕장']

    rip_list = []

    # 현재 시간
    # 현재 시간을 UTC로 설정
    current_datetime = datetime.now(pytz.utc)

    # 한국 시간대로 변환
    korean_tz = pytz.timezone('Asia/Seoul')
    current_datetime = current_datetime.astimezone(korean_tz)
    search_date = current_datetime.strftime("%Y%m%d")
    
    for i in range(len(obs_code)):

        url = f"http://www.khoa.go.kr/api/oceangrid/ripCurrent/search.do?ServiceKey={service_key}&BeachCode={obs_code[i]}&Date={search_date}&ResultType=json"
        response = requests.get(url)
        data = response.json()

        # 필요 항목 추출
        item_list = data['result']['data']
        last_rip_data = item_list[-1]['score']
        rip_list.append(last_rip_data)

    min_index = rip_list.index(min(rip_list))

    return f'이안류 수치가 {rip_list[min_index]}로 가장 낮은 {obs_ko[min_index]}을 추천드립니다.'

# 해수욕 지수 -> 예외처리 코드 추가하기
def sea_status(text):
    from datetime import datetime, timedelta
    import pytz
    import requests

    # 인증키
    service_key = '4NK/rglt3c7VdkaTYoRPug=='

    # 가져올 해수욕장 코드 임랑, 송정, 해운대
    # obs_code = ['BCH002', 'BCH013', 'BCH012', 'BCH010', 'BCH008', 'BCH172', 'BCH001']
    # obs_ko = ['광안리 해수욕장', '다대포 해수욕장', '송도 해수욕장', '송정 해수욕장', '일광 해수욕장', '임랑 해수욕장', '해운대 해수욕장']
    
    obs_code = ['BCH002', 'BCH013', 'BCH012', 'BCH010', 'BCH008', 'BCH001']
    obs_ko = ['광안리 해수욕장', '다대포 해수욕장', '송도 해수욕장', '송정 해수욕장', '일광 해수욕장', '해운대 해수욕장']

    # 한국 시간대로 변환
    # korean_tz = pytz.timezone('Asia/Seoul')
    current_datetime = datetime.now(pytz.timezone('Asia/Seoul'))
    # search_date = current_datetime.strftime("%Y%m%d")
    hour = current_datetime.strftime("%H")
    date = ""

    if int(hour) < 12:
        date = "오전"
    else:
        date = "오후"

    sea_status_list = []
    sea_status_textlist = []

    for i in range(len(obs_code)):

        url = f"http://www.khoa.go.kr/api/oceangrid/beach/search.do?ServiceKey={service_key}&BeachCode={obs_code[i]}&ResultType=json"
        response = requests.get(url)
        data = response.json()

        # 필요 항목 추출
        item_list = data['result']['data']
        if date == '오전':
            last_sea_status_data = item_list[0]["day1_am_status"]
        elif date == '오후':
            last_sea_status_data = item_list[0]["day1_pm_status"]
        
        if last_sea_status_data == '매우좋음':
            sea_status_list.append(1)
        elif last_sea_status_data == '좋음':
            sea_status_list.append(2)
        elif last_sea_status_data == '보통':
            sea_status_list.append(3)
        elif last_sea_status_data == '나쁨':
            sea_status_list.append(4)
        elif last_sea_status_data == '매우나쁨':
            sea_status_list.append(5)
            
        sea_status_textlist.append(last_sea_status_data)
        
    min_index = sea_status_list.index(min(sea_status_list))
    
    if sea_status_textlist[min_index] == '매우나쁨':
        script_text = wave_api('status')
        return f"현재 모든 해수욕장의 해수욕 지수가 '{sea_status_textlist[min_index]}'으로 {script_text}"
    else:
        return f'현재 해수욕 지수가 {sea_status_textlist[min_index]}로 가장 좋은 {obs_ko[min_index]}을 추천드립니다.'

# guide
def guide_list(text):
    if text == 'login':
        return '메뉴바에서 로그인 버튼 클릭 > ID, PW을 입력 후 로그인 버튼 클릭'
    elif text == 'join':
        return '메뉴바에서 회원가입 버튼 클릭 > ID, PW 등을 입력 후 회원가입 버튼 클릭'
    elif text == 'photo_upload':
        return '메뉴바에서 커뮤니티 버튼 클릭 > 해수욕장 (포토 스팟) 클릭 > 업로드 버튼 클릭 > 내용 작성 후 업로드'
    elif text == 'photo_search':
        return '메뉴바에서 커뮤니티 버튼 클릭 > 해수욕장 (포토 스팟) 클릭 > 방문단위를 선택하여 원하는 게시글만 조건 조회'
    elif text == 'photo_change':
        return '메뉴바에서 커뮤니티 버튼 클릭 > 해수욕장 (포토 스팟) 클릭 > 본인이 업로드한 포스트 클릭 > 수정 버튼 클릭 > 내용 수정 후 업로드'
    elif text == 'photo_del':
        return '메뉴바에서 커뮤니티 버튼 클릭 > 해수욕장 (포토 스팟) 클릭 > 본인이 업로드한 포스트 클릭 > 삭제 버튼 클릭'
    elif text == 'food_upload':
        return '메뉴바에서 커뮤니티 버튼 클릭 > 해수욕장 (맛집 리뷰) 클릭 > 업로드 버튼 클릭 > 내용 작성 후 업로드'
    elif text == 'food_search':
        return '메뉴바에서 커뮤니티 버튼 클릭 > 해수욕장 (맛집 리뷰) 클릭 > 방문단위를 선택하여 원하는 게시글만 조건 조회'
    elif text == 'food_change':
        return '메뉴바에서 커뮤니티 버튼 클릭 > 해수욕장 (맛집 리뷰) 클릭 > 본인이 업로드한 포스트 클릭 > 수정 버튼 클릭 > 내용 수정 후 업로드'
    elif text == 'food_del':
        return '메뉴바에서 커뮤니티 버튼 클릭 > 해수욕장 (맛집 리뷰) 클릭 > 본인이 업로드한 포스트 클릭 > 삭제 버튼 클릭'
    elif text == 'service':
        return '1) 메인 페이지에서 시작하기 버튼 클릭 > 지도에서 조회를 뭔하는 지역구 선택 > 조회하고 싶은 해수욕장 카드를 선택하여 조회 2) 메뉴바에서 해수욕장 신호등 버튼 클릭 > 지도에서 조회를 뭔하는 지역구 선택 > 조회하고 싶은 해수욕장 카드를 선택하여 조회'

@app.route('/api/request/jfish', methods=['POST'])
def jfish_pip():

    
    request_data = request.get_json()
    obs_code = request_data.get('obs_code')
    
    model = jfish_model
    
    # 인증키
    service_key = '4NK/rglt3c7VdkaTYoRPug=='

    # 가져올 해수욕장 코드 임랑, 송정, 해운대
    # obs_code = ['TW_0092', 'TW_0090', 'TW_0062']
    url = f"http://www.khoa.go.kr/api/oceangrid/buObsRecent/search.do?ServiceKey={service_key}&ObsCode={obs_code}&ResultType=json"
    response = requests.get(url)
    data = response.json()

    # 필요 항목 추출
    # ['air_pressure', 'air_temper', 'water_temper', 'wave', 'tide_level', 'salinity']
    item_list = data['result']['data']

    # wind_speed = item_list['wind_speed']
    air_pressure = item_list['air_pres']
    air_temper = item_list['air_temp']
    water_temper = item_list['water_temp']
    wave = item_list['wave_height']
    salinity = item_list['Salinity']

    # 조위 데이터(tide_level) api 호출 시작
    # 현재 시간을 UTC로 설정
    current_datetime = datetime.now(pytz.utc)

    # 한국 시간대로 변환
    korean_tz = pytz.timezone('Asia/Seoul')
    current_datetime = current_datetime.astimezone(korean_tz)
    search_date = current_datetime.strftime("%Y%m%d")

    code = 'DT_0005'
    url = f"http://www.khoa.go.kr/api/oceangrid/tideCurPre/search.do?ServiceKey={service_key}&ObsCode={code}&Date={search_date}&ResultType=json"
    response = requests.get(url)
    data = response.json()
    item_list = data['result']['data']
    tide_level = item_list[-1]['real_value']
    # 조위 데이터(tide_level) api 호출 끝

    data = [[air_pressure, air_temper, water_temper, wave, tide_level, salinity]]
    col = ['air_pressure', 'air_temper', 'water_temper', 'wave', 'tide_level', 'salinity']
    df = pd.DataFrame(data, columns=col)

    # 타입 변경
    df['air_pressure'] = df['air_pressure'].astype(float)
    df['air_temper'] = df['air_temper'].astype(float)
    df['water_temper'] = df['water_temper'].astype(float)
    df['wave'] = df['wave'].astype(float)
    df['tide_level'] = df['tide_level'].astype(float)
    df['salinity'] = df['salinity'].astype(float)

    pred = model.predict(df)
    answer = pred[0].astype(float)
    # 요청 처리 후 응답 반환
    response = {
        'message' : f'{answer}'
    }
    return jsonify(response)

# 앱 실행
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)