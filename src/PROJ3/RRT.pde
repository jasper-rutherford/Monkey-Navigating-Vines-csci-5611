//RRT Object. It generates/stores all the points/paths and stuff.
//Initially made for project 1, modified to work here.
//CSCI 5611 Project 3.2
// Jasper Rutherford <ruthe124@umn.edu>

public class RRT
{
  public ArrayList<Node> nodes;
  
  //the range of acceptable distances between connected nodes 
  public float minNodeDist = armspan * .0;
  public float maxNodeDist = armspan * .75;
  

  public RRT(ArrayList<VineNode> vineNodes)
  {
    generateNodes(vineNodes);
  }

  public void generateNodes(ArrayList<VineNode> vineNodes)
  {
    //initialize the list
    nodes = new ArrayList<Node>();

    //create goal node at banana1
    nodes.add(new Node(map.banana1, null));

    //add all nodes from vineNodes to the tree
    while (vineNodes.size() != 0)
    {
      //loops through all vineNodes in reverse order so that they can be removed without needing to change lcv
      for (int lcv = vineNodes.size() - 1; lcv >= 0; lcv--)
      {
        //get the next point from vineNodes
        Vec2 point = vineNodes.get(lcv).pos;

        //find the nearest node
        Node nearest = nearestNode(point);

        //check if the distance to the nearestNode is between the set minimum/maximum distances
        if (minNodeDist < nearest.pos.minus(point).length() && nearest.pos.minus(point).length() < maxNodeDist)
        {
          //create a node for the point with the nearest node as its previous node
          //the constructor automatically adds this new node to nearest's list of nextNodes
          Node node = new Node(point, nearest);

          //adapt the path to keep the rrt optimalish
          for (int lcv2 = 0; lcv2 < nodes.size(); lcv2++)
          {
            //the node being checked for adaptation
            Node aNode = nodes.get(lcv2);


            //if the node could get to the goal faster by going to the new node
            //than by going to its previous node
            float a = node.dist + aNode.pos.distanceTo(node.pos);
            float b = aNode.dist;
            // println(a + " < " + b);
            if (a < b)
            {
              //only consider the node for optimization if between the set minimum/maximum distances
              if (minNodeDist < aNode.pos.minus(node.pos).length() && aNode.pos.minus(node.pos).length() < maxNodeDist)
              {
                //remove this node from its previous node's list of nextNodes
                aNode.prev.nexts.remove(aNode);

                //set the new node to be this node's new previous node
                aNode.prev = node;

                //add this node to node's nextList
                aNode.prev.nexts.add(aNode);

                //update this node's distance
                //(this function also updates the dists for all the nodes that lead to this node)
                aNode.updateDist();
              }
            }
          }

          //add the new node to the list of nodes (this is after the optimization so that the new node doesn't try to path through itself)
          nodes.add(node);

          //remove the vineNode from the list
          vineNodes.remove(lcv);
        }
      }
    }
  }

  //returns the node in the list of nodes that is closest to the given point
  //assumes that nodes.size() > 0
  public Node nearestNode(Vec2 point)
  {
    //defaults to first node
    Node nearNode = nodes.get(0);
    float minDist = nearNode.pos.distanceTo(point);

    //skips the first node because it is the default
    for (int lcv = 1; lcv < nodes.size(); lcv++)
    {
      Node aNode = nodes.get(lcv);
      float aDist = aNode.pos.distanceTo(point);

      //if the node in question has a smaller distance than the previously found minDist
      if (aDist < minDist)
      {
        //set the node in question to be the nearNode
        nearNode = aNode;
        minDist = aDist;
      }
    }

    return nearNode;
  }

  public void drawGraph()
  {
    //Draw Nodes
    fill(0);
    for (int lcv = 0; lcv < nodes.size(); lcv++)
    {
      Node aNode = nodes.get(lcv);
      circle(aNode.pos.x, aNode.pos.y, 5);
    }

    //Draw edges
    //(calling this on the goal node will have it cascade out to all nodes)
    nodes.get(0).drawEdges();
  }
}
