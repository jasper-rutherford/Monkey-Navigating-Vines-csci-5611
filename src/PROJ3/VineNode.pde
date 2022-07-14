//Represents the parts of a vine that can be grabbed
//CSCI 5611 Project 3.2
// Jasper Rutherford <ruthe124@umn.edu>

public class VineNode
{
  public Vec2 pos;
  public ArrayList<VineNode> neighbors;  //neighbor vineNodes are nodes that are closer than armspan

  public VineNode(Vec2 pos)
  {
    this.pos = pos;
    neighbors = new ArrayList<>();
  }

  //populates this node's list of neighbors
  public void findNeighbors(ArrayList<VineNode> vineNodes)
  {
    //check all vineNodes
    for (int lcv = 0; lcv < vineNodes.size(); lcv++)
    {
      //two vineNodes are neighbors if they are less than armspan distance from each other (a vineNode cannot be its own neighbor)
      float dist = vineNodes.get(lcv).pos.minus(pos).length(); 
      if (dist != 0 && dist < armspan * .75)
      {
        neighbors.add(vineNodes.get(lcv));
      }
    }
  }
}
