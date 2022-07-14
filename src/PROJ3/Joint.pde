//Represents a joint between two bones.
//CSCI 5611 Project 3.2
// Jasper Rutherford <ruthe124@umn.edu>

public class Joint
{
  public float ang;
  public float angSpeed;
  public Vec2 pos;

  //constructor that defaults angSpeed to pi / 50
  public Joint(float ang, Vec2 pos)
  {
    this.ang = ang;
    this.angSpeed = pi / 75;
    this.pos = pos;
  }
  
  //constructor that lets you configure angSpeed
  public Joint(float ang, Vec2 pos, float angSpeed)
  {
    this.ang = ang;
    this.angSpeed = angSpeed;
    this.pos = pos;
  }
}
