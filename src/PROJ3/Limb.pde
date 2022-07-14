//contains various bones and joints and makes them move together
//CSCI 5611 Project 3.2
// Jasper Rutherford <ruthe124@umn.edu>

public class Limb
{
  public ArrayList<Bone> bones;
  public ArrayList<Joint> joints;

  //the index of this limb in limbs
  public int index;

  //the sum of all the lengths of all the bones
  public float len;

  //used for variables that try to hold a specific set of angles
  //true when those angles are held
  public boolean solved;

  public Limb(ArrayList<Bone> bones, ArrayList<Joint> joints, int index)
  {
    this.bones = bones;
    this.joints = joints;
    this.index = index;

    len = 0;
    for (int lcv = 0; lcv < bones.size(); lcv++)
    {
      len += bones.get(lcv).len;
    }

    fk();
  }

  //this was ripped and loosely translated (and loopified) from "IK_Exercise" activity on canvas
  public void fk()
  {
    //move root relative to limb that it is attached to

    //midsection stays anchored to the center of the arm limb (so that the arm limb looks like two arms working together)
    // or anchor to end of limb1
    if (index == 2)
    {
      //anchor to limb0
      if (limbs[0] != null)
      {
        joints.get(0).pos = limbs[0].joints.get(2).pos;
      }
      //anchor to limb1
      else
      {
        joints.get(0).pos = limbs[1].joints.get(2).pos;
      }
    }
    //left leg stays anchored to the end of limb2 or the 3rd joint in limb3 (indexed from 0)
    else if (index == 5)
    {
      //anchor to limb2
      if (limbs[2] != null)
      {
        joints.get(0).pos = limbs[2].joints.get(1).pos;
      }
      //anchor to limb3
      else
      {
        joints.get(0).pos = limbs[3].joints.get(3).pos;
      }
    }
    //right leg stays anchored to the end of limb2 or the 3rd joint in limb4 (indexed from 0)
    else if (index == 6)
    {
      //anchor to limb2
      if (limbs[2] != null)
      {
        joints.get(0).pos = limbs[2].joints.get(1).pos;
      }
      //anchor to limb4
      else
      {
        joints.get(0).pos = limbs[4].joints.get(3).pos;
      }
    }
    //left active leg anchors to the middle of limb3
    else if (index == 7)
    {
      joints.get(0).pos = limbs[3].joints.get(3).pos;
    }
    //inactive arm not on vine stays anchored to end of limb1 or 2nd node (indexed from 0) of limb 2 or 3
    else if (index == 8)
    {
      //anchor to limb1
      if (limbs[1] != null)
      {
        joints.get(0).pos = limbs[1].joints.get(2).pos;
      }
      //anchor to limb3
      else if (limbs[3] != null)
      {
        joints.get(0).pos = limbs[3].joints.get(2).pos;
      }
      //anchor to limb4
      else
      {
        joints.get(0).pos = limbs[4].joints.get(2).pos;
      }
    }

    //calculate the positions of all the other joints in this limb
    float angleSum = 0;
    for (int lcv = 0; lcv < joints.size() - 1; lcv++)
    {
      Joint joint = joints.get(lcv);
      angleSum += joint.ang;
      joints.get(lcv + 1).pos = new Vec2(cos(angleSum) * bones.get(lcv).len, sin(angleSum) * bones.get(lcv).len).plus(joint.pos);
    }

    //update banana coords if they have been grabbed
    if (index == 6 && grabbedBanana1)
    {
      map.banana1 = joints.get(joints.size() - 1).pos;
    }
    if (index == 5 && grabbedBanana2)
    {
      map.banana2 = joints.get(joints.size() - 1).pos;
    }
  }

  //this was ripped and loosely translated (and loopified) from "IK_Exercise" activity on canvas
  void solve()
  {
    //Limb 0 alternates back and forth toward banana1 until root is within legReach * .6 of both bananas
    if (index == 0)
    {
      float distanceToB1 = map.banana1.minus(joints.get(0).pos).length();
      float distanceToB2 = map.banana2.minus(joints.get(0).pos).length();
      
      //arms path toward bananas until both bananas are closer to the root than legReach * .6 or until the end of the rrt is reached
      if ((distanceToB1 > legReach * .6 || distanceToB2 > legReach * .6) && armsGoal != null)
      {
        Vec2 startToGoal, startToEndEffector;
        float dotProd, angleDiff;

        for (int lcv = joints.size() - 2; lcv >= 0; lcv--)
        {
          //Update joint
          Joint joint = joints.get(lcv);
          startToGoal = armsGoal.pos.minus(joint.pos);
          startToEndEffector = joints.get(joints.size() - 1).pos.minus(joint.pos);
          dotProd = dot(startToGoal.normalized(), startToEndEffector.normalized());
          dotProd = clamp(dotProd, -1, 1);
          angleDiff = acos(dotProd);
          if (cross(startToGoal, startToEndEffector) < 0)
            joint.ang += min(angleDiff, joint.angSpeed);
          else
            joint.ang -= min(angleDiff, joint.angSpeed);

          fk(); //Update link positions with fk (e.g. end effector changed)
        }

        //if goal has been reached
        Vec2 endpoint = joints.get(joints.size() - 1).pos;
        if (abs(endpoint.x - armsGoal.pos.x) < 1 && abs(endpoint.y - armsGoal.pos.y) < 1)
        {
          //advance goal to next node
          armsGoal = armsGoal.prev;

          //create a new limb with all the same orientation as the current limb, but reversed with a root at the endpoint
          ArrayList<Bone> newBones = new ArrayList<>();

          for (int lcv = bones.size() - 1; lcv >= 0; lcv--)
          {
            newBones.add(bones.get(lcv));
          }

          ArrayList<Joint> newJoints = new ArrayList<>();

          for (int lcv = joints.size() - 1; lcv >= 0; lcv--)
          {
            Joint joint = joints.get(lcv);
            newJoints.add(joint);

            //fix the joint's angle info
            //angle is made negative
            joint.ang = -joint.ang;
          }

          Vec2 dir = newJoints.get(1).pos.minus(newJoints.get(0).pos);
          newJoints.get(0).ang = atan2(dir.y, dir.x);

          //switch out arm in the list with a reversed arm
          limbs[0] = new Limb(newBones, newJoints, 0);
        }
      }
      //close enough to banana to reach it with feet
      //build the relevant limbs from the current limbs and then clear the current limbs from the array
      else
      {
        makeLimb3();
        makeLimb7();
        makeLimb8();

        limbs[0] = null;
        limbs[2] = null;
        limbs[5] = null;
        limbs[6] = null;
      }
    }
    //Limb 1 points up and slightly away from the body, in a direction dependent on which side of the screen the root is
    else if (index == 1)
    {
      //point up and to the left
      if (joints.get(0).pos.x < 200)
      {
        float angGoals[] = {pi / 2, -pi / 4, 0};

        solved = true;
        for (int lcv = 0; lcv < angGoals.length; lcv++)
        {
          Joint joint = joints.get(lcv);
          float angleDiff =  angGoals[lcv] - joint.ang;

          if (angleDiff > pi)
          {
            angleDiff -= 2 * pi;
          } else if (angleDiff < -pi)
          {
            angleDiff += 2 * pi;
          }

          if (angleDiff > 0)
          {
            joint.ang += min(angleDiff, joint.angSpeed);
          } else
          {
            joint.ang += max(angleDiff, -joint.angSpeed);
          }

          if (abs(angleDiff) > 0.01)
          {
            solved = false;
          }
        }

        limbFlip = true;
      }
      //point up and to the right
      else
      {
        float angGoals[] = {pi / 2, pi / 4, 0};

        solved = true;
        for (int lcv = 0; lcv < angGoals.length; lcv++)
        {
          Joint joint = joints.get(lcv);
          float angleDiff =  angGoals[lcv] - joint.ang;

          if (angleDiff > pi)
          {
            angleDiff -= 2 * pi;
          } else if (angleDiff < -pi)
          {
            angleDiff += 2 * pi;
          }

          if (angleDiff > 0)
          {
            joint.ang += min(angleDiff, joint.angSpeed);
          } else
          {
            joint.ang += max(angleDiff, -joint.angSpeed);
          }

          if (abs(angleDiff) > 0.01)
          {
            solved = false;
          }
        }
      }
    }
    //Limb 2 hangs straight down.
    else if (index == 2)
    {
      float angGoals[] = {pi / 2, 0};

      solved = true;
      for (int lcv = 0; lcv < angGoals.length; lcv++)
      {
        Joint joint = joints.get(lcv);
        float angleDiff =  angGoals[lcv] - joint.ang;

        if (angleDiff > pi)
        {
          angleDiff -= 2 * pi;
        } else if (angleDiff < -pi)
        {
          angleDiff += 2 * pi;
        }

        if (angleDiff > 0)
        {
          joint.ang += min(angleDiff, joint.angSpeed);
        } else
        {
          joint.ang += max(angleDiff, -joint.angSpeed);
        }

        if (abs(angleDiff) > 0.01)
        {
          solved = false;
        }
      }
    }
    //Limb 3 reaches for banana1
    else if (index == 3)
    {
      Vec2 startToGoal, startToEndEffector;
      float dotProd, angleDiff;

      for (int lcv = joints.size() - 2; lcv >= 0; lcv--)
      {
        //Update joint
        Joint joint = joints.get(lcv);
        startToGoal = map.banana1.minus(joint.pos);
        startToEndEffector = joints.get(joints.size() - 1).pos.minus(joint.pos);
        dotProd = dot(startToGoal.normalized(), startToEndEffector.normalized());
        dotProd = clamp(dotProd, -1, 1);
        angleDiff = acos(dotProd);
        if (cross(startToGoal, startToEndEffector) < 0)
          joint.ang += min(angleDiff, joint.angSpeed);
        else
          joint.ang -= min(angleDiff, joint.angSpeed);

        fk(); //Update link positions with fk (e.g. end effector changed)
      }

      //if banana has been reached
      Vec2 endpoint = joints.get(joints.size() - 1).pos;
      if (abs(endpoint.x - map.banana1.x) < 1 && abs(endpoint.y - map.banana1.y) < 1)
      {
        //if the other leg still hasnt grabbed its banana yet, readjust the limbs so that there is a long leg starting from the arm on the vine
        if (limbs[7] != null)
        {
          makeLimb4();
          makeLimb6();

          limbs[3] = null;
          limbs[7] = null;
        }
        //if the other leg has grabbed its banana, readjust limbs to end config
        else
        {
          makeLimb1();
          makeLimb2();
          makeLimb6();

          limbs[3] = null;
        }

        grabbedBanana1 = true;
      }
    }
    //limb4 reaches for banana2
    else if (index == 4)
    {
      Vec2 startToGoal, startToEndEffector;
      float dotProd, angleDiff;

      for (int lcv = joints.size() - 2; lcv >= 0; lcv--)
      {
        //Update joint
        Joint joint = joints.get(lcv);
        startToGoal = map.banana2.minus(joint.pos);
        startToEndEffector = joints.get(joints.size() - 1).pos.minus(joint.pos);
        dotProd = dot(startToGoal.normalized(), startToEndEffector.normalized());
        dotProd = clamp(dotProd, -1, 1);
        angleDiff = acos(dotProd);
        if (cross(startToGoal, startToEndEffector) < 0)
          joint.ang += min(angleDiff, joint.angSpeed);
        else
          joint.ang -= min(angleDiff, joint.angSpeed);

        fk(); //Update link positions with fk (e.g. end effector changed)
      }

      //if banana has been reached
      Vec2 endpoint = joints.get(joints.size() - 1).pos;
      if (abs(endpoint.x - map.banana2.x) < 1 && abs(endpoint.y - map.banana2.y) < 1)
      {
        //readjust limbs to end config
        makeLimb1();
        makeLimb2();
        makeLimb5();

        limbs[4] = null;

        grabbedBanana2 = true;
      }
    }
    //limb5 hangs
    else if (index == 5)
    {
      float angGoals[] = {pi * 3 / 4, -pi / 4, 0, 0};

      solved = true;
      for (int lcv = 0; lcv < angGoals.length; lcv++)
      {
        Joint joint = joints.get(lcv);
        float angleDiff =  angGoals[lcv] - joint.ang;

        if (angleDiff > pi)
        {
          angleDiff -= 2 * pi;
        } else if (angleDiff < -pi)
        {
          angleDiff += 2 * pi;
        }

        if (angleDiff > 0)
        {
          joint.ang += min(angleDiff, joint.angSpeed);
        } else
        {
          joint.ang += max(angleDiff, -joint.angSpeed);
        }

        if (abs(angleDiff) > 0.01)
        {
          solved = false;
        }
      }
    }
    //limb 6 hangs
    else if (index == 6)
    {
      float angGoals[] = {pi * 1 / 4, pi * 1 / 4, 0, 0};

      solved = true;
      for (int lcv = 0; lcv < angGoals.length; lcv++)
      {
        Joint joint = joints.get(lcv);
        float angleDiff =  angGoals[lcv] - joint.ang;

        if (angleDiff > pi)
        {
          angleDiff -= 2 * pi;
        } else if (angleDiff < -pi)
        {
          angleDiff += 2 * pi;
        }

        if (angleDiff > 0)
        {
          joint.ang += min(angleDiff, joint.angSpeed);
        } else
        {
          joint.ang += max(angleDiff, -joint.angSpeed);
        }

        if (abs(angleDiff) > 0.01)
        {
          solved = false;
        }
      }
    }
    //limb 7 moves toward banana2
    else if (index == 7)
    {
      Vec2 startToGoal, startToEndEffector;
      float dotProd, angleDiff;

      for (int lcv = joints.size() - 2; lcv >= 0; lcv--)
      {
        //Update joint
        Joint joint = joints.get(lcv);
        startToGoal = map.banana2.minus(joint.pos);
        startToEndEffector = joints.get(joints.size() - 1).pos.minus(joint.pos);
        dotProd = dot(startToGoal.normalized(), startToEndEffector.normalized());
        dotProd = clamp(dotProd, -1, 1);
        angleDiff = acos(dotProd);
        if (cross(startToGoal, startToEndEffector) < 0)
          joint.ang += min(angleDiff, joint.angSpeed);
        else
          joint.ang -= min(angleDiff, joint.angSpeed);

        fk(); //Update link positions with fk (e.g. end effector changed)
      }

      //if banana has been reached
      Vec2 endpoint = joints.get(joints.size() - 1).pos;
      if (abs(endpoint.x - map.banana2.x) < 1 && abs(endpoint.y - map.banana2.y) < 1)
      {
        //readjust limbs so that the shorter leg is inactive
        makeLimb5();

        limbs[7] = null;

        grabbedBanana2 = true;
      }
    }
    //limb 8 hangs down by the monkey's side
    else
    {
      //hang one way or another depending on which way the arm holding onto the vine points
      if (!limbFlip)
      {
        float angGoals[] = {pi * 3 / 4, -pi / 4, 0};

        solved = true;
        for (int lcv = 0; lcv < angGoals.length; lcv++)
        {
          Joint joint = joints.get(lcv);
          float angleDiff =  angGoals[lcv] - joint.ang;

          if (angleDiff > pi)
          {
            angleDiff -= 2 * pi;
          } else if (angleDiff < -pi)
          {
            angleDiff += 2 * pi;
          }

          if (angleDiff > 0)
          {
            joint.ang += min(angleDiff, joint.angSpeed);
          } else
          {
            joint.ang += max(angleDiff, -joint.angSpeed);
          }

          if (abs(angleDiff) > 0.01)
          {
            solved = false;
          }
        }
      } else
      {
        float angGoals[] = {pi / 4, pi / 4, 0};

        solved = true;
        for (int lcv = 0; lcv < angGoals.length; lcv++)
        {
          Joint joint = joints.get(lcv);
          float angleDiff =  angGoals[lcv] - joint.ang;

          if (angleDiff > pi)
          {
            angleDiff -= 2 * pi;
          } else if (angleDiff < -pi)
          {
            angleDiff += 2 * pi;
          }

          if (angleDiff > 0)
          {
            joint.ang += min(angleDiff, joint.angSpeed);
          } else
          {
            joint.ang += max(angleDiff, -joint.angSpeed);
          }

          if (abs(angleDiff) > 0.01)
          {
            solved = false;
          }
        }
      }
    }
  }

  public void update()
  {
    fk();
    solve();
  }

  public void drawBones()
  {
    if (drawDebugColors)
    {
      //set color according to index
      if (index == 0)
      {
        fill(255, 0, 0);
      } else if (index == 1)
      {
        fill(255, 247, 0);
      } else if (index == 2)
      {
        fill(64, 255, 0);
      } else if (index == 3)
      {
        fill(51, 245, 196);
      } else if (index == 4)
      {
        fill(51, 103, 245);
      } else if (index == 5)
      {
        fill(130, 43, 207);
      } else if (index == 6)
      {
        fill(189, 25, 180);
      } else if (index == 7)
      {
        fill(0, 0, 0);
      } else if (index == 8)
      {
        fill(255, 255, 255);
      }
    } else
    {
      fill(87, 63, 41);
    }
    float angleSum = 0;
    for (int lcv = 0; lcv < bones.size(); lcv++)
    {
      Joint joint = joints.get(lcv);
      angleSum += joint.ang;
      pushMatrix();
      translate(joint.pos.x, joint.pos.y);
      rotate(angleSum);
      rect(0, -bones.get(lcv).wid/2, bones.get(lcv).len, bones.get(lcv).wid);
      popMatrix();
    }
    fill(100, 100, 100);
  }
}
