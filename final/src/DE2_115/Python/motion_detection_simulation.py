'''
import cv2
import numpy as np

# 開啟網路攝影機
cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)

# 設定影像尺寸
width = 1280
height = 960

# 設定擷取影像的尺寸大小
cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)

# 計算畫面面積
area = width * height

# 初始化平均影像
ret, frame = cap.read()
avg = cv2.blur(frame, (4, 4))
avg_float = np.float32(avg)

M_t = frame
V_t = np.zeros(frame.shape)

while(cap.isOpened()):
  # 讀取一幅影格
  ret, frame = cap.read()

  # 若讀取至影片結尾，則跳出
  if ret == False:
    break

  # 模糊處理
  blur = cv2.blur(frame, (4, 4))

  # 計算目前影格與平均影像的差異值
  diff = cv2.absdiff(avg, blur)

  # 將圖片轉為灰階
  gray = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)

  # 篩選出變動程度大於門檻值的區域
  ret, thresh = cv2.threshold(gray, 25, 255, cv2.THRESH_BINARY)

  # 使用型態轉換函數去除雜訊
  kernel = np.ones((5, 5), np.uint8)
  thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel, iterations=2)
  thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel, iterations=2)

  # 產生等高線
  cntimg, cnts = cv2.findContours(thresh.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

  for c in cntimg:
    # 忽略太小的區域
    if cv2.contourArea(c) < 2500:
      continue

    # 偵測到物體，可以自己加上處理的程式碼在這裡…

    # 計算等高線的外框範圍
    (x, y, w, h) = cv2.boundingRect(c)

    # 畫出外框
    cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)

  # 畫出等高線（除錯用）
  #cv2.drawContours(frame, cntimg, -1, (0, 255, 255), 2)

  # 顯示偵測結果影像
  cv2.imshow('frame', frame)

  if cv2.waitKey(1) == 27:
    break

  # 更新平均影像
  cv2.accumulateWeighted(blur, avg_float, 0.01)
  avg = cv2.convertScaleAbs(avg_float)

cap.release()
cv2.destroyAllWindows()
'''
import cv2
import numpy as np

# 開啟網路攝影機
cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)

# 設定影像尺寸
width = 1280
height = 960

# 設定擷取影像的尺寸大小
cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)

# 計算畫面面積
area = width * height

# 初始化平均影像
ret, frame = cap.read()
frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
frame = np.float32(frame)

M_t = frame
V_t = np.zeros(frame.shape)
E_t = np.zeros(frame.shape)

N = 6
m = 32
while(cap.isOpened()):
    # 讀取一幅影格
    ret, frame = cap.read()
    I_t = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    I_t = np.float32(I_t)

    # 若讀取至影片結尾，則跳出
    if ret == False:
        break

    # 計算目前影格與平均影像的差異值
    diff = I_t - M_t
    # step 1:
    M_t += np.sign(diff)
    #M_t[E_t == 0] += np.sign(diff)[E_t == 0]
    # step 2:
    O_t = np.abs(diff)
    # step 3:
    V_t += np.sign(N*O_t - V_t)
    V_t = np.maximum(np.minimum(V_t, 2**m - 1), 2)
    # step 4:
    E_t = np.sign(O_t - V_t)
    E_t[E_t < 0] = 0
    E_t = E_t * 255
    # 產生等高線
    cntimg, cnts = cv2.findContours(
        np.uint8(E_t), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    for c in cntimg:
        # 忽略太小的區域
        if cv2.contourArea(c) < 1500:
            continue
        # 計算等高線的外框範圍
        (x, y, w, h) = cv2.boundingRect(c)

        # 畫出外框
        cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
    # print(thresh.shape)
    # 顯示偵測結果影像
    cv2.imshow('frame', E_t)

    if cv2.waitKey(1) == 27:
        break

cap.release()
cv2.destroyAllWindows()
