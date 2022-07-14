//maps the world and paths to goals.
//CSCI 5611 Project 3.2
// Jasper Rutherford <ruthe124@umn.edu>

public class Map
{
  public float[][] vines;  // vines[n][0] = the xposition of the nth vine, vines[n][1] = the length of the nth vine
  public int numVines;
  public ArrayList<VineNode> vineNodes;
  public Vec2 banana1;
  public Vec2 banana2;
  public RRT rrt;


  public Map(int numVines, float minVineLength, float maxVineLength)
  {
    this.numVines = numVines;
    vines = new float[numVines][2];
    vineNodes = new ArrayList<>();

    //generate vines
    for (int lcv = 0; lcv < numVines; lcv++)
    {
      vines[lcv][0] = width / numVines * lcv;               //uniformly distribute vines across the screen
      vines[lcv][1] = random(minVineLength, maxVineLength); //give vines a random length

      //add a bunch of nodes along the vine (and one at the end of the vine) as grab points
      for (int lcv2 = 0; lcv2 < vines[lcv][1] + 40; lcv2 += 40)
      {
        //add a node at the very end of the vine
        if (lcv2 > vines[lcv][1])
        {
          vineNodes.add(new VineNode(new Vec2(vines[lcv][0], vines[lcv][1])));
        }
        //add nodes along the vine
        else
        {
          vineNodes.add(new VineNode(new Vec2(vines[lcv][0], lcv2)));
        }
      }
    }

    //after all vines/vineNodes have been generated, generate each vineNode's neighbor list
    for (int lcv = 0; lcv < vineNodes.size(); lcv++)
    {
      vineNodes.get(lcv).findNeighbors(vineNodes);
    }

    //generate two bananas by (at?) a random vineNode and remove that node from the list (removed for rrt purposes)
    VineNode bananaNode = vineNodes.get(int(random(0, vineNodes.size())));               //get random vineNode
    vineNodes.remove(bananaNode);                                                        //remove vineNode from list
    banana1 = bananaNode.pos;                                                            //set banana1 to the vineNode
    banana2 = bananaNode.neighbors.get(int(random(0, bananaNode.neighbors.size()))).pos; //set banana2 to a random neighbor of the vineNode
  }

  public void generateRRT()
  {
    //generate an rrt from the vineNodes
    rrt = new RRT(vineNodes);
  }

  public void drawStuff()
  {
    //draw vines
    stroke(47, 97, 49);
    for (int lcv = 0; lcv < numVines; lcv++)
    {
      strokeWeight(2);
      line(vines[lcv][0], 0, vines[lcv][0], vines[lcv][1]);
    }
    stroke(100, 100, 100);

    //texture bananas
    noStroke();
    float hX = (float)(20 * Math.sin(Math.PI / 4));  //helper values for drawing the image
    float hY = (float)(20 * Math.cos(Math.PI / 4));
    pushMatrix();
    translate(banana1.x, banana1.y);
    beginShape();
    texture(imgBanana);
    vertex( - hX, -hY, 0, 0, 0);
    vertex(hX, -hY, 0, imgBanana.width, 0);
    vertex(hX, hY, 0, imgBanana.width, imgBanana.height);
    vertex( -hX, hY, 0, 0, imgBanana.height);
    endShape();
    popMatrix();

    hX = (float)(20 * Math.sin(Math.PI / 4));  //helper values for drawing the image
    hY = (float)(20 * Math.cos(Math.PI / 4));
    pushMatrix();
    translate(banana2.x, banana2.y);
    beginShape();
    texture(imgBanana);
    vertex( - hX, -hY, 0, 0, 0);
    vertex(hX, -hY, 0, imgBanana.width, 0);
    vertex(hX, hY, 0, imgBanana.width, imgBanana.height);
    vertex( -hX, hY, 0, 0, imgBanana.height);
    endShape();
    popMatrix();

    if (drawGraph)
    {
      rrt.drawGraph();
    }
  }
}
