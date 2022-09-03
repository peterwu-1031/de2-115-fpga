#include <Servo.h>

Servo myservo;
int servopin = 9;
int laserpin = 4;
int killpin = 5;
int p1 = 6;
int p2 = 7;
int p3 = 8;
void setup() {
  // put your setup code here, to run once:
  myservo.attach(4);
  //pinMode(laserpin, OUTPUT);
  pinMode(killpin, INPUT);
  pinMode(p1, INPUT);
  pinMode(p2, INPUT);
  pinMode(p3, INPUT);
  Serial.begin(9600);
}

void loop() {
  // put your main code here, to run repeatedly:
  int vkill = digitalRead(killpin);
  int vp1 = digitalRead(p1);
  int vp2 = digitalRead(p2);
  int vp3 = digitalRead(p3);
  Serial.println("signal: ");
  Serial.println(vkill);
  Serial.println(vp1);
  Serial.println(vp2);
  Serial.println(vp3);
  vkill = 0;
  //digitalWrite(laserpin, HIGH);
  if(vkill == 1){
    int degree = 100*(4*vp1+2*vp2+vp3)/7;
    Serial.println("deg");
    Serial.println(degree);
    degree = 90;
    myservo.write(degree);
    delay(1000);
    Serial.println("shoot");
    for (int i=0;i<10;i++){
      digitalWrite(laserpin, HIGH);
      delay(100);
      digitalWrite(laserpin, LOW);
      delay(100);
    }
  }
  else{
    digitalWrite(laserpin, LOW);
    Serial.println("not shoot");
    myservo.write(0);
    delay(3000);
    myservo.write(90);
    delay(3000);   
  }
}
