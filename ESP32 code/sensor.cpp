//pin definition
const int trigPin = 3;
const int echoPin = 2;
const int vibratorPin = 4;

long duration;
int distance;

void setup() {
  Serial.begin(9600);
  
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(vibratorPin, OUTPUT);
  
  digitalWrite(vibratorPin, LOW);
}

void loop() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  duration = pulseIn(echoPin, HIGH);
  
  distance = duration * 0.034 / 2;
  
  Serial.print("Distance: ");
  Serial.print(distance);
  Serial.println(" cm");
  
  if (distance > 0 && distance <= 60) {
    digitalWrite(vibratorPin, HIGH); 
  } else {
    digitalWrite(vibratorPin, LOW);  
  }
  
  delay(100);
}

