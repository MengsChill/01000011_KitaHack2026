// Define the new pins connected to the components
const int trigPin = 3;       // Trigger pin of the ultrasonic sensor (D3)
const int echoPin = 2;       // Echo pin of the ultrasonic sensor (D2)
const int vibratorPin = 4;   // Pin controlling the vibration motor (D4)

// Variables to store duration and calculated distance
long duration;
int distance;

void setup() {
  // Initialize the serial monitor for debugging
  Serial.begin(9600);
  
  // Configure the pins as Output or Input
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(vibratorPin, OUTPUT);
  
  // Make sure the vibrator is off when the system starts
  digitalWrite(vibratorPin, LOW);
}

void loop() {
  // 1. Clear the trigPin to ensure a clean pulse
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  
  // 2. Send a 10-microsecond HIGH pulse to trigger the sensor
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  // 3. Read the echoPin (returns the sound wave travel time in microseconds)
  duration = pulseIn(echoPin, HIGH);
  
  // 4. Calculate the distance in centimeters
  // Speed of sound is ~0.034 cm/microsecond. Divide by 2 for the round trip.
  distance = duration * 0.034 / 2;
  
  // Print distance to Serial Monitor to help you test and troubleshoot
  Serial.print("Distance: ");
  Serial.print(distance);
  Serial.println(" cm");
  
  // 5. Trigger the vibrator logic
  // We check if distance > 0 to filter out occasional sensor errors
  if (distance > 0 && distance <= 60) {
    digitalWrite(vibratorPin, HIGH); // Turn ON the vibrator
  } else {
    digitalWrite(vibratorPin, LOW);  // Turn OFF the vibrator
  }
  
  // Short delay before the next loop to keep the sensor stable
  delay(100);
}
