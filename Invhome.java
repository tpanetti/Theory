import java.io.FileNotFoundException;
import java.io.File;
import java.util.Scanner;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Iterator;
public class Invhome
{
  public static void main(String[] args) throws FileNotFoundException
  {
    //parse DFA
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
    //pasre homo
    //maybe check for \n as instead but we'll do that once it fails
    input = new Scanner(new File(args[1]));
    line=input.nextLine();
    String inAlph = (line.substring(line.indexOf(":") +2));
    String[] inAlphabet = inAlph.split("");
    line=input.nextLine();
    String outAlph = (line.substring(line.indexOf(":")+2));
    //TODO: Possibly set the delimiter to \n after this
    String[] outAlphabet = outAlph.split("");
    ArrayList<String> homos= new ArrayList<String>();
    // input.useDelimiter("\n");
    while(input.hasNext())
      homos.add(input.nextLine());
    // homos.add(input.nextLine());
    // for(String str : inAlphabet)
    //   System.out.println(str);
    // for(String str : outAlphabet)
    //   System.out.println(str);
    // for(String str : homos)
    //   System.out.println(str);

      //build the inverse dfa
  ArrayList<Node> newDFA = new ArrayList<Node>();
  for(int i=0; i< nodes.size(); i++)
  {
    Node newNode = new Node();
    if(nodes.get(i).accepts)
      newNode.accepts = true;
    else
      newNode.accepts = false;
    newNode.nodeIndex = i;
    HashMap<String,String> newMap = new HashMap<String,String>();

    for(int j=0; j<homos.size();j++)
    {
      String iter = inAlphabet[j];
      if(homos.get(j).length() == 0){
        // System.out.println("Size is zero, so skip?");
        //Is it just starting state?
        newMap.put(inAlphabet[j],i+"");
        continue;
      }
      String[] arr = homos.get(j).split("");
      Node iterr = nodes.get(i);
      // System.out.println("iterator starts at: " + iter);
      for(int k=0; k<arr.length;k++)
      {
        // System.out.println(arr[k] + ":" +iterr.map.get(arr[k]));
        //get the closure
        iter = iterr.map.get(arr[k]);
        iterr = getNode(nodes, iter);
      }
      newMap.put(inAlphabet[j],iter);
    }
    newNode.map = newMap;
    newDFA.add(newNode);
  }
  printDFA(newDFA, inAlphabet);


  // for(int i =0; i < nodes.size(); i++)
  // {
  //   Node newNode = new Node();
  //   if(nodes.get(i).accepts)
  //     newNode.accepts = true;
  //   else
  //     newNode.accepts = false;
  //   newNode.index = i;
  //   HashMap<String,String> newMap = new HashMap<String,String>();
  //   String iter = alpha[0];
  //   for(int j=0 j< homos.size();j++)
  //   {
  //     String closure = homos.get(j);
  //     //set the iterator to the first character of the old alphabet (aka starting state)
  //     iter = nodes.get(i).map.get()
  //   }
  //
  // }

    // findHomo(nodes);
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
  public static void printDFA(ArrayList<Node> nodes, String[] alphabet)
  {
    System.out.println("Number of states: " + nodes.size());
    System.out.print("Accepting states: ");
    for(Node temp : nodes)
      if(temp.accepts)
        System.out.print(temp.nodeIndex + " ");
    System.out.println();
    System.out.print("Alphabet: ");
    for(String str : alphabet)
      System.out.print(str);
    System.out.println();

    for(Node node : nodes)
		{
      for(int i=0; i < node.map.size();i++)
      {
        System.out.print(node.map.get(alphabet[i]) + " ");
      }
      System.out.println();
		// System.out.println(node.nodeIndex + ": " + node.accepts);
		// System.out.println(node.map);
		}
  }
}
