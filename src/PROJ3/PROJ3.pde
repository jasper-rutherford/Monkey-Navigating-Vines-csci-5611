//A monkey navigates some vines to eat some bananas
//CSCI 5611 Project 3.2
// Jasper Rutherford <ruthe124@umn.edu>

Map map;
float armBoneLen = 20;
float midBoneLen = 35;
float legBoneLen = 15;

float armspan = armBoneLen * 4;
float legReach = armBoneLen * 2 + midBoneLen + legBoneLen * 3;
float neckLength = 7;
boolean grabbedBanana1;
boolean grabbedBanana2;

//used to describe which way the spare arm should hang at the end
boolean limbFlip;

/*
 Limbs go in the following slots:
 This unintuitive order was chosen because limbs toward the end tend to be rooted in limbs that are toward the beginning
 0 - active arms                (combines both arms into one arm, roots one end and moves the other end toward the next vine node) [4 segments]
 1 - other inactive arm         (arm on the vine just hangs onto the vine)                                                         [2 segments]
 2 - midsection                 (midsection hangs aimlessly)                                                                       [1 segments]
 3 - long right leg             (from the arm on the vine through the midsection to the end of the right leg, moves to banana 1)   [6 segments]
 4 - long left leg              (same but to the end of the left leg, moves to banana 2)                                           [6 segments]
 5 - inactive short left leg    (left leg hang aimlessly)                                                                          [3 segments]
 6 - inactive short right leg   (right leg hangs aimlessly)                                                                        [3 segments]
 7 - active short left leg      (left leg moves to banana 2)                                                                       [3 segments]
 8 - inactive arm               (arm not hanging onto the vine hangs aimlessly)                                                    [2 segments]
 */
Limb limbs[];

PImage imgBanana;
PImage imgMonkeyHead;

Node armsGoal;
boolean drawGraph = false;
boolean autoRestart = true;
boolean drawDebugColors = false;

//helper float
float pi = 3.141527;

void setup()
{
  size(400, 400, P3D);
  surface.setTitle("monke");

  //armspan is initialized here so that it can be used in the creation of the rrt
  //legReach is initialized here because it makes sense to initialize it next to armspan. obviously.

  grabbedBanana1 = false;
  grabbedBanana2 = false;

  limbFlip = false;

  limbs = new Limb[9];

  //load the images
  imgBanana = loadImage("\\..\\images\\banana.jpg");
  imgMonkeyHead = loadImage("\\..\\images\\monkey.png");

  //resize the images
  imgBanana.resize(30, 30);
  imgMonkeyHead.resize(80, 80);

  //make the map (vines, nodes, rrt, etc)
  map = new Map(int(random(20, 30)), 100, 350);
  map.generateRRT();
  armsGoal = map.rrt.nearestNode(new Vec2(200, 200));

  //make the limbs
  makeLimb0();
  makeLimb2();
  makeLimb5();
  makeLimb6();
}

//make the arms (one limb that reverses itself repeatedly, made to look like two arms working together)
void makeLimb0()
{
  //make the bones
  ArrayList<Bone> bones = new ArrayList<>();
  for (int lcv = 0; lcv < 4; lcv++)
  {
    bones.add(new Bone(armBoneLen, 5));
  }

  ArrayList<Joint> joints = new ArrayList<>();

  //root
  //spawn the monkey on the nearest vineNode to 200 200, and set the goal accordingly
  joints.add(new Joint(0, armsGoal.pos));  //arm root is initially the nearest node to 200, 200
  joints.add(new Joint(0, null));
  joints.add(new Joint(0, null));
  joints.add(new Joint(0, null));
  joints.add(new Joint(0, null));

  //after root is set to goal, goal is advanced
  armsGoal = armsGoal.prev;

  limbs[0] = new Limb(bones, joints, 0);
}

//make the inactive arm on the vine
void makeLimb1()
{
  ArrayList<Bone> bones = new ArrayList<>();
  ArrayList<Vec2> posList = new ArrayList<>();
  //extract from limb 3 if limb 3 exists
  if (limbs[3] != null)
  {
    bones.add(limbs[3].bones.get(0));
    bones.add(limbs[3].bones.get(1));

    posList.add(limbs[3].joints.get(0).pos);
    posList.add(limbs[3].joints.get(1).pos);
    posList.add(limbs[3].joints.get(2).pos);
  }
  //otherwise extract from limb 4
  else
  {
    bones.add(limbs[4].bones.get(0));
    bones.add(limbs[4].bones.get(1));

    posList.add(limbs[4].joints.get(0).pos);
    posList.add(limbs[4].joints.get(1).pos);
    posList.add(limbs[4].joints.get(2).pos);
  }
  ArrayList<Float> angs = solveAngles(posList);

  ArrayList<Joint> joints = new ArrayList<>();
  for (int lcv = 0; lcv < angs.size(); lcv++)
  {
    joints.add(new Joint(angs.get(lcv), posList.get(lcv)));
  }

  limbs[1] = new Limb(bones, joints, 1);
}

//make the midsection
void makeLimb2()
{
  //if limb0 exists, then create limb from scratch
  if (limbs[0] != null)
  {
    //make the bone
    ArrayList<Bone> bone = new ArrayList<>();
    bone.add(new Bone(midBoneLen, 10));

    //make the joints
    ArrayList<Joint> joints = new ArrayList<>();
    joints.add(new Joint(pi / 2, null));
    joints.add(new Joint(0, null));

    //make a limb from the bones and joints
    limbs[2] = new Limb(bone, joints, 2);
  }
  //otherwise if limb3 exist, extract this limb from that one
  else if (limbs[3] != null)
  {
    ArrayList<Bone> bones = new ArrayList<>();
    bones.add(limbs[3].bones.get(2));

    ArrayList<Vec2> posList = new ArrayList<>();
    posList.add(limbs[3].joints.get(2).pos);
    posList.add(limbs[3].joints.get(3).pos);

    ArrayList<Float> angs = solveAngles(posList);

    ArrayList<Joint> joints = new ArrayList<>();
    for (int lcv = 0; lcv < angs.size(); lcv++)
    {
      joints.add(new Joint(angs.get(lcv), posList.get(lcv)));
    }

    limbs[2] = new Limb(bones, joints, 2);
  }
  //otherwise limb4 must exist, and extract this limb from that one
  else
  {
    ArrayList<Bone> bones = new ArrayList<>();
    bones.add(limbs[4].bones.get(2));

    ArrayList<Vec2> posList = new ArrayList<>();
    posList.add(limbs[4].joints.get(2).pos);
    posList.add(limbs[4].joints.get(3).pos);

    ArrayList<Float> angs = solveAngles(posList);

    ArrayList<Joint> joints = new ArrayList<>();
    for (int lcv = 0; lcv < angs.size(); lcv++)
    {
      joints.add(new Joint(angs.get(lcv), posList.get(lcv)));
    }

    limbs[2] = new Limb(bones, joints, 2);
  }
}

//make a limb composed of the part of the arm that is rooted up to the midsection, the midsection, and the right leg
void makeLimb3()
{
  ArrayList<Bone> bones = new ArrayList<>();
  bones.add(limbs[0].bones.get(0));
  bones.add(limbs[0].bones.get(1));
  bones.add(limbs[2].bones.get(0));
  bones.add(limbs[6].bones.get(0));
  bones.add(limbs[6].bones.get(1));
  bones.add(limbs[6].bones.get(2));

  ArrayList<Vec2> posList = new ArrayList<>();
  posList.add(limbs[0].joints.get(0).pos);
  posList.add(limbs[0].joints.get(1).pos);
  posList.add(limbs[0].joints.get(2).pos);
  posList.add(limbs[6].joints.get(0).pos);
  posList.add(limbs[6].joints.get(1).pos);
  posList.add(limbs[6].joints.get(2).pos);
  posList.add(limbs[6].joints.get(3).pos);

  ArrayList<Float> angs = solveAngles(posList);

  ArrayList<Joint> joints = new ArrayList<>();
  for (int lcv = 0; lcv < angs.size(); lcv++)
  {
    joints.add(new Joint(angs.get(lcv), posList.get(lcv)));
  }

  limbs[3] = new Limb(bones, joints, 3);
}

//make long active left leg
void makeLimb4()
{
  ArrayList<Bone> bones = new ArrayList<>();
  bones.add(limbs[3].bones.get(0));
  bones.add(limbs[3].bones.get(1));
  bones.add(limbs[3].bones.get(2));
  bones.add(limbs[7].bones.get(0));
  bones.add(limbs[7].bones.get(1));
  bones.add(limbs[7].bones.get(2));

  ArrayList<Vec2> posList = new ArrayList<>();
  posList.add(limbs[3].joints.get(0).pos);
  posList.add(limbs[3].joints.get(1).pos);
  posList.add(limbs[3].joints.get(2).pos);
  posList.add(limbs[3].joints.get(3).pos);
  posList.add(limbs[7].joints.get(1).pos);
  posList.add(limbs[7].joints.get(2).pos);
  posList.add(limbs[7].joints.get(3).pos);

  ArrayList<Float> angs = solveAngles(posList);

  ArrayList<Joint> joints = new ArrayList<>();
  for (int lcv = 0; lcv < angs.size(); lcv++)
  {
    joints.add(new Joint(angs.get(lcv), posList.get(lcv)));
  }

  limbs[4] = new Limb(bones, joints, 4);
}

//make hanging left leg
void makeLimb5()
{
  //if limb 7 exists, create this limb from limb 7
  if (limbs[7] != null)
  {
    limbs[5] = limbs[7];
    limbs[5].index = 5;
  }
  //if limb 4 exists, extract this limb from that one
  else if (limbs[4] != null)
  {
    ArrayList<Bone> bones = new ArrayList<>();
    bones.add(limbs[4].bones.get(3));
    bones.add(limbs[4].bones.get(4));
    bones.add(limbs[4].bones.get(5));

    ArrayList<Vec2> posList = new ArrayList<>();
    posList.add(limbs[4].joints.get(3).pos);
    posList.add(limbs[4].joints.get(4).pos);
    posList.add(limbs[4].joints.get(5).pos);
    posList.add(limbs[4].joints.get(6).pos);

    ArrayList<Float> angs = solveAngles(posList);

    ArrayList<Joint> joints = new ArrayList<>();
    for (int lcv = 0; lcv < angs.size(); lcv++)
    {
      joints.add(new Joint(angs.get(lcv), posList.get(lcv)));
    }

    limbs[5] = new Limb(bones, joints, 5);
  }
  //otherwise create this limb from scratch
  else
  {
    //make the bones
    ArrayList<Bone> bones = new ArrayList<>();
    for (int lcv = 0; lcv < 3; lcv++)
    {
      bones.add(new Bone(legBoneLen, 5));
    }

    ArrayList<Joint> joints = new ArrayList<>();
    joints.add(new Joint(pi * 3 / 4, null));
    joints.add(new Joint(-pi * 1 / 4, null));
    joints.add(new Joint(0, null));
    joints.add(new Joint(0, null));

    limbs[5] = new Limb(bones, joints, 5);
  }
}

//make hanging right leg
void makeLimb6()
{
  //if limb3 exists then extract this limb from that one
  if (limbs[3] != null)
  {
    ArrayList<Bone> bones = new ArrayList<>();
    bones.add(limbs[3].bones.get(3));
    bones.add(limbs[3].bones.get(4));
    bones.add(limbs[3].bones.get(5));

    ArrayList<Vec2> posList = new ArrayList<>();
    posList.add(limbs[3].joints.get(3).pos);
    posList.add(limbs[3].joints.get(4).pos);
    posList.add(limbs[3].joints.get(5).pos);
    posList.add(limbs[3].joints.get(6).pos);

    ArrayList<Float> angs = solveAngles(posList);

    ArrayList<Joint> joints = new ArrayList<>();
    for (int lcv = 0; lcv < angs.size(); lcv++)
    {
      joints.add(new Joint(angs.get(lcv), posList.get(lcv)));
    }

    limbs[6] = new Limb(bones, joints, 6);
  }
  //otherwise make the limb from scratch
  else
  {
    //make the bones
    ArrayList<Bone> bones = new ArrayList<>();
    for (int lcv = 0; lcv < 3; lcv++)
    {
      bones.add(new Bone(legBoneLen, 5));
    }

    ArrayList<Joint> joints = new ArrayList<>();
    joints.add(new Joint(pi * 1 / 4, null));
    joints.add(new Joint(pi * 1 / 4, null));
    joints.add(new Joint(0, null));
    joints.add(new Joint(0, null));

    limbs[6] = new Limb(bones, joints, 6);
  }
}

//short left leg (active)
void makeLimb7()
{
  limbs[7] = limbs[5];
  limbs[7].index = 7;
}

//inactive arm not on vine
void makeLimb8()
{
  ArrayList<Bone> bones = new ArrayList<>();
  bones.add(limbs[0].bones.get(2));
  bones.add(limbs[0].bones.get(3));

  ArrayList<Vec2> posList = new ArrayList<>();
  posList.add(limbs[0].joints.get(2).pos);
  posList.add(limbs[0].joints.get(3).pos);
  posList.add(limbs[0].joints.get(4).pos);

  ArrayList<Float> angs = solveAngles(posList);

  ArrayList<Joint> joints = new ArrayList<>();
  for (int lcv = 0; lcv < angs.size(); lcv++)
  {
    joints.add(new Joint(angs.get(lcv), posList.get(lcv)));
  }

  limbs[8] = new Limb(bones, joints, 8);
}

//takes a list of vec2 points and calculates the angles between them as if they were joints, returns a float list of angles (last angle is always zero, because it is unused)
ArrayList<Float> solveAngles(ArrayList<Vec2> posList)
{
  //create list of the real angles for each point
  ArrayList<Float> reals = new ArrayList<>();
  for (int lcv = 0; lcv < posList.size() - 1; lcv++)
  {
    Vec2 dir = posList.get(lcv + 1).minus(posList.get(lcv));
    reals.add(atan2(dir.y, dir.x));
  }

  //convert real angles to relative angles, usable for joints
  ArrayList<Float> relatives = new ArrayList<>();

  //first angle is relative to nothing, therefore just itself
  relatives.add(reals.get(0));

  //the middle angles are their real angle minus the real angle of the angle before it
  for (int lcv = 1; lcv < reals.size(); lcv++)
  {
    relatives.add(reals.get(lcv) - reals.get(lcv - 1));
  }

  //last angle doesn't matter, it is never used.
  relatives.add(0.0);

  return relatives;
}

void draw()
{
  //solve();
  background(81, 191, 17);

  map.drawStuff();

  //update the limbs
  for (int lcv = 0; lcv < limbs.length; lcv++)
  {
    if (limbs[lcv] != null)
    {
      limbs[lcv].update();
    }
  }

  //draw the limbs
  noStroke();
  for (int lcv = 0; lcv < limbs.length; lcv++)
  {
    if (limbs[lcv] != null)
    {
      limbs[lcv].drawBones();
    }
  }

  //draw the monkey head
  //get info about the monkey's spine
  Vec2 clavicle, tailbone;

  //if limb2 exists extract from limb2
  if (limbs[2] != null)
  {
    clavicle = limbs[2].joints.get(0).pos;
    tailbone = limbs[2].joints.get(1).pos;
  }
  //if limb3 exists extract from limb3
  else if (limbs[3] != null)
  {
    clavicle = limbs[3].joints.get(2).pos;
    tailbone = limbs[3].joints.get(3).pos;
  }
  //otherwise extract from limb4
  else
  {
    clavicle = limbs[4].joints.get(2).pos;
    tailbone = limbs[4].joints.get(3).pos;
  }

  //calculate the angle and coordinates
  Vec2 dir = clavicle.minus(tailbone);
  float angle = atan2(dir.y, dir.x) + pi / 2;
  dir.setToLength(neckLength);
  clavicle.add(dir);

  //draw the monkey head at those coordinates and that angle
  beginShape();
  float hX = (float)(neckLength * 2 * Math.sin(Math.PI / 4));  //helper values for drawing the image
  float hY = (float)(neckLength * 2 * Math.cos(Math.PI / 4));
  pushMatrix();
  translate(clavicle.x, clavicle.y);
  rotateZ((float)angle);
  beginShape();
  texture(imgMonkeyHead);
  vertex( -hX, -hY, 0, 0, 0);
  vertex(hX, -hY, 0, imgMonkeyHead.width, 0);
  vertex(hX, hY, 0, imgMonkeyHead.width, imgMonkeyHead.height);
  vertex( -hX, hY, 0, 0, imgMonkeyHead.height);
  endShape();
  popMatrix();

  //check if all limbs are in final positions (for auto restart)
  if (autoRestart && limbs[1] != null && limbs[1].solved && limbs[2] != null && limbs[2].solved && limbs[5] != null && limbs[5].solved && limbs[6] != null && limbs[6].solved && limbs[8] != null && limbs[8].solved)
  {
    setup();
  }
}

void keyPressed()
{
  if (key == 'g' || key == 'G')
  {
    drawGraph = !drawGraph;
  }

  if (key == 'r' || key == 'R')
  {
    setup();
  }

  if (key == 'a' || key == 'A')
  {
    autoRestart = !autoRestart;
  }

  if (key == 'b' || key == 'B')
  {
    drawDebugColors = !drawDebugColors;
  }
}
