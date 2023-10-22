## DEMO Video
https://www.youtube.com/watch?v=20aysfmDwVc&t=307s
## Structure
```
DE2_115_CAMERA (Motion Detection)
├── CCD_Capture.v(Capture camera frames)
├── CalcDir.v
├── DE2_115_CAMERA.v
├── I2C_CCD_Config.v(D5M module's I2C)
├── I2C_Controller.v
├── Line_Buffer.v
├── Line_Buffer1.v
├── Motion_Detection.v
├── Purify
│   ├── Purify.v(Reduce noise)
│   ├── Purify_Line_Buffer.v
│   ├── Purify_Line_Buffer_bb.v
│   └── Purify_buffer_3.v(The line buffer is used to store the previous row's data)
├── RAW2RGB.v(Convert D5M data to RGB format)
├── Reset_Delay.(Output reset signal)
├── SEG7_LUT.v
├── SEG7_LUT_8.v(Seven-segment display)
├── Sdram_Control
│   ├── Sdram_Control.v
│   ├── Sdram_Params.h
│   ├── Sdram_RD_FIFO.v
│   ├── Sdram_WR_FIFO.v
│   ├── command.v
│   ├── control_interface.v
│   └── sdr_data_path.v
├── VGA_Controller.v(Control VGA display)
└── sdram_pll.v
```
```
DE2_115 (Game Control)
├── Arduino_Module
│   └── DCLab_Servo_Laser.ino(Receive signal from Top via GPIO and control Arduino to implement laser)
├── Audio_Processing
│   ├── AudDSP.sv(Control playback speed)
│   ├── AudPlayer.sv(Play sounds)
│   ├── AudRecorder.sv(Write sound effects into SRAM)
│   ├── AudTop.sv(Select and play specific sound effect based on the signal in the Game)
│   └── I2cInitializer.sv(Control I2C protocal and initialize wm8731)
├── DE2_115(Setup Configured Documents)
├── Debounce.sv(Handle key debounce issues)
├── Image_Processing
│   ├── display.sv(Control VGA's output signal)
│   ├── item.sv(Control game picture's display)
│   ├── rom_async.sv(Control fpga's LUT/ROM)
│   ├── rom_sync.sv(Control BRAM)
│   └── sprite_1.sv(Control game picture's display)
├── Python
│   ├── img2mem.py(Convert images into .mem files in hexadecimal format)
│   └── motion_detection_simulation.py(Simulate motion detection algorithm)
├── SevenHexDecoder.sv(Control seven-segment display)
├── Top.sv(Integrate all submodules and control the Game's finite-state machine)
├── lfsr.sv(Generate random numbers as input for AudDSP playback speed)
├── pictures(store game pictures)
└── timer.sv(Display countdown timer on the screen during the game)
