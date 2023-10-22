# DEMO Video
https://www.youtube.com/watch?v=20aysfmDwVc&t=307s
# Structure
```
DE2_115_CAMERA (Motion Detection)
├── CCD_Capture.v (Capture camera frames)
├── CalcDir.v
├── DE2_115_CAMERA.v
├── I2C_CCD_Config.v (D5M module's I2C)
├── I2C_Controller.v
├── Line_Buffer.v
├── Line_Buffer1.v
├── Motion_Detection.v
├── Purify
│   ├── Purify.v (Reduce noise)
│   ├── Purify_Line_Buffer.v
│   ├── Purify_Line_Buffer_bb.v
│   └── Purify_buffer_3.v (The line buffer is used to store the last row's data)
├── RAW2RGB.v (Convert D5M raw data to RGB data)
├── Reset_Delay.v (Output reset signal)
├── SEG7_LUT.v
├── SEG7_LUT_8.v (Seven-segment display)
├── Sdram_Control
│   ├── Sdram_Control.v
│   ├── Sdram_Params.h
│   ├── Sdram_RD_FIFO.v
│   ├── Sdram_WR_FIFO.v
│   ├── command.v
│   ├── control_interface.v
│   └── sdr_data_path.v
├── VGA_Controller.v (Control VGA display)
└── sdram_pll.v
```
```
DE2_115 (Game Control)
├── Arduino_Module
│   └── DCLab_Servo_Laser.ino (Receive signals from Top via GPIO and control the laser module)
├── Audio_Processing
│   ├── AudDSP.sv (Control playback speed)
│   ├── AudPlayer.sv (Play sound effects)
│   ├── AudRecorder.sv (Write sound effects into SRAM)
│   ├── AudTop.sv (Select a specific sound effect based on the signal from the Game)
│   └── I2cInitializer.sv (Control the I2C protocal and initialize wm8731)
├── DE2_115(Setup Configured Documents)
├── Debounce.sv (Handle key debounce issues)
├── Image_Processing
│   ├── display.sv (Control VGA's output signals)
│   ├── item.sv (Control game image display)
│   ├── rom_async.sv (Control FPGA's LUT/ROM)
│   ├── rom_sync.sv (Control BRAM)
│   └── sprite_1.sv (Control game image display)
├── Python
│   ├── img2mem.py (Convert images into .mem files in hexadecimal format)
│   └── motion_detection_simulation.py (Simulate the motion detection algorithm)
├── SevenHexDecoder.sv (Control seven-segment display)
├── Top.sv (Integrate all submodules and control the Game's finite-state machine)
├── lfsr.sv (Generate random numbers as input for AudDSP playback speed)
├── pictures (store game images)
└── timer.sv (Display countdown timer on the screen during the game)
```
# Block Diagram
## DE2-115 Camera (Motion Detecter)
   ![圖片 5](https://github.com/peterwu-1031/de2-115/assets/56571300/38c26dd5-05a7-4639-bfb6-0bfaa90f53d1)
## Top (Game)
   ![圖片 6_0](https://github.com/peterwu-1031/de2-115/assets/56571300/9d0b8ac6-ca37-4ba7-996e-93176d67b516)
# FSM
![圖片 7_0](https://github.com/peterwu-1031/de2-115/assets/56571300/a6981605-7fdb-4662-9c31-41e69150d750)
# Materials
DE2-115*2, TRDB-D5M camera, Arduino Nano, SG90 servo motor, Laser module, Dupont wire, Microphone, Speaker, Screen, VGA cable, Power cord.
# Implementation Methods and Design Details
## Motion Detection
We chose the algorithm shown in the following image for motion detection with the consideration of processing speed and implementation complexity on FPGA.This algorithm reads the image from the camera, then calculates the difference between it and the estimated background Mt. If the absolute value of this difference is less than the variance Vt, the pixel is considered not in motion. In contrast, if the absolute difference is greater than Vt, the pixel is classified as in motion. The values of Mt and Vt are updated based on the magnitude of the difference. After performing the motion detection computation, we also implemented a noise removal step. For each pixel, if all surrounding pixels are classified as not in motion, then this pixel is also considered not in motion. This process reduces noise in the image, enhancing the precision of the motion detection.
![圖片 10_0](https://github.com/peterwu-1031/de2-115/assets/56571300/8480dcd4-4b60-4a62-9aa0-3b426b50c4dd) <br>
To recognize the left-right movement of objects, we horizontally divided the frame into seven segments. We calculated the number of motion-detected pixels in each segment. The segment with the highest number of pixels was selected. If the pixel count in that segment exceeded a predefined threshold, the corresponding movement signal was sent to the game control FPGA board.
## Image Display
As for image display, we referred to (https://projectf.io/posts/hardware-sprites/) using
img2mem.py to save each images as separate pixel and palette files. The palette represents the colors used in the image, while the pixel file indicates the index of each pixel's color in the palette. We stored game images with a palette of 16 colors, and each color was represented by 4 bits for each RGB channel. An example is shown below:
Palette: 
![圖片 12_0](https://github.com/peterwu-1031/de2-115/assets/56571300/8d0040e1-db6b-4297-aff5-54efc68914bf)
Pixel: 
![圖片 13_0](https://github.com/peterwu-1031/de2-115/assets/56571300/f8cf3bdc-3c47-475f-a89e-2f4df48031de) <br>
A pixel value of 1 (indicated by the red box) represents that the color of this pixel is the first color in the palette file, which is ACC. Likely, a pixel value of 5 (indicated by the green box) corresponds to the fifth color in the palette file, which is 9BD. We stored the smaller palette file in ROM with smaller capacity, while the larger pixel file was stored in Block RAM with larger capacity. This design choice helped reduce latency and memory usage. The design of storing images directly in the FPGA eliminated the need for a computer host in our gaming device. This setup allows the game to be executed anywhere without reliance on a computer host, making it closer to the real gaming environment.
