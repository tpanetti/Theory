import java.io.FileNotFoundException;
import java.io.File;
import java.util.Scanner;
import java.util.ArrayList;
import java.util.HashMap;
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
    for(int i=0;i<nodes.size();i++)
      for(int j=0;j<nodes.size();j++)
        table[i][j]=false;

    //Loop through the states
    //Step 2: Consider every state pair (Qi, Qj) in the DFA where Qi ∈ F
    //and Qj ∉ F or vice versa and mark them.
    int i =0;
    for(Node state : nodes)
    {
      //If that state does not accept, skip
      if(!state.accepts)
        continue;
      int j =0;
      for(Node otherState : nodes)
      {
        if(otherState.accepts)
          continue;
        //state = Qi, otherState = Qj, Qi = F, Qj != F
        //mark it zero dude
        table[i][j] = true;
        j++;
      }
      i++;
    }
    //Step 3: If there is an unmarked pair (Qi, Qj), mark it if the pair
    //{δ(Qi, A), δ (Qi, A)} is marked for some input alphabet
    //In layman's
    //check unmarked states (i,j) if either can move to an accepting
    //state, mark it zero dude
    for(i =0; i < table.length;i++)
      for(int j=0; j<table[i].length;j++)
      {
        if(table[i][j] == true)
          continue;
        Node index = nodes.get(i);
        Node jindex = nodes.get(j);
        Iterator iIterator = index.map.entrySet().iterator();
      }


  }

  public static void printDFA(ArrayList<Node> nodes)
  {

  }



}
