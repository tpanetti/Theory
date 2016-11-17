import java.io.FileNotFoundException;
import java.io.File;
import java.util.Scanner;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Iterator;
public class Minimizer
{
  public static void main(String[] args) throws FileNotFoundException
  {
    Scanner input = new Scanner(new File(args[0]));

		String line = input.nextLine();
		int states = Integer.parseInt(line.substring(line.indexOf(":") +2));

		line = input.nextLine();
			ArrayList<Integer> acceptingState = new ArrayList<Integer>();
			//parse the line for accepting states
			Scanner temp = new Scanner(line);
			temp.next();temp.next();
			while(temp.hasNext())
			{

				acceptingState.add(temp.nextInt());

			}
			temp.close();
		ArrayList<Node> nodes = new ArrayList<Node>();
		//get the alphabet?
		String tempLine = input.nextLine();
		String alphabet = tempLine.substring(tempLine.indexOf(":")+2);
		String[] alpha = alphabet.split("");
		//grab state input
		for(int i =0; i < states; i++)
		{
			Node state = new Node();
			if(acceptingState.contains(i))
				state.accepts = true;
			else
				state.accepts = false;

			state.nodeIndex = i;
			//reuse line and temp cause why not
			state.map = new HashMap<String,String>();
			line = input.nextLine();
			temp = new Scanner(line);
			for(int j =0; temp.hasNext(); j++)
			{
				state.map.put(alpha[j], temp.next());
			}
			nodes.add(state);
		}
    minimizeDFA(nodes);


  }

  public static void minimizeDFA(ArrayList<Node> nodes)
  {
    boolean[][] table = new boolean[nodes.size()][nodes.size()];
    ArrayList<Node> minimizedDFA = new ArrayList<Node>();
    //falsify the array
    for(int i=0;i<nodes.size() /2;i++)
      for(int j=0;j<nodes.size() /2;j++)
        table[i][j]=false;

    // for(int i=nodes.size()/2; i<nodes.size();i++)
      // for(int j=nodes.size()/2;j<nodes.size();j++)
        // table[i][j]=true;
    for(int i=0;i<nodes.size();i++)
    {
      for(int j=i;j<nodes.size();j++)
      {
        table[i][j]=true;
      }
    }
    //Loop through the states
    //Step 2: Consider every state pair (Qi, Qj) in the DFA where Qi ∈ F
    //and Qj ∉ F or vice versa and mark them.
    for(int i=0; i < nodes.size(); i++)
    {
      for(int j=0; j < nodes.size(); j++)
      {
        Node stateI = nodes.get(i);
        Node stateJ = nodes.get(j);
        if((stateI.accepts && !stateJ.accepts) ||
           (!stateI.accepts && stateJ.accepts))
          table[i][j] = true;

      }
    }



    // int i =0;
    // for(Node state : nodes)
    // {
    //   //If that state does not accept, skip
    //   if(!state.accepts)
    //   {
    //     i++;
    //     continue;
    //   }
    //   int j =0;
    //   for(Node otherState : nodes)
    //   {
    //     if(otherState.accepts && state.nodeIndex != otherState.nodeIndex)
    //     {
    //       j++;
    //       continue;
    //     }
    //     //state = Qi, otherState = Qj, Qi = F, Qj != F
    //     //mark it zero dude
    //     table[i][j] = true;
    //     // table[j][i] = true;
    //     j++;
    //   }
    //   i++;
    // }
    //Step 3: If there is an unmarked pair (Qi, Qj), mark it if the pair
    //{δ(Qi, A), δ (Qi, A)} is marked for some input alphabet
    //In layman's
    //check unmarked states (i,j) if either can move to an accepting
    //state, mark it zero dude
    // for(i =0; i < table.length;i++)
    // {
    //   for(int j=0; j<table[i].length;j++)
    //   {
    //     if(table[i][j] == true)
    //       continue;
    //     Node index = nodes.get(i);
    //     Node jindex = nodes.get(j);
    //     Iterator iterator = index.map.entrySet().iterator();
    //     while(iterator.hasNext())
    //     {
    //       Map.Entry<String,String> pair = (Map.Entry)iterator.next();
    //       // String val = pair.getValue();
    //       if(getNode(nodes,pair.getValue()).accepts)
    //         table[i][j] = true;
    //       iterator.remove();
    //     }
    //     iterator = jindex.map.entrySet().iterator();
    //     while(iterator.hasNext())
    //     {
    //       Map.Entry<String,String> pair = (Map.Entry)iterator.next();
    //       if(getNode(nodes,pair.getValue()).accepts)
    //         table[i][j] = true;
    //       iterator.remove();
    //     }
    //   }
    // }
    //TESTING println
    for(int i =0; i < table.length;i++)
    {
      System.out.print("[");
      for(int j=0; j < table[i].length;j++)
        System.out.print(table[i][j] + ", ");
      System.out.println("]");
    }
  }

  public static Node getNode(ArrayList<Node> nodes, String move)
	{
		// System.out.println("Stupid string is: " +move);
		int state = Integer.parseInt(move);
		for(Node iter : nodes)
		{
			if(iter.nodeIndex == state)
				return iter;
		}
		//can't move
		return null;
	}
  public static void printDFA(ArrayList<Node> nodes)
  {


  }



}
