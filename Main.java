import java.util.Scanner;
import java.util.ArrayList;
public class Main
{
	public static void main(String[] args)
	{
		Scanner input = new Scanner(System.in);
		int states = input.nextInt();
		String line = input.nextLine();
		ArrayList<Integer> acceptingState = new ArrayList<Integer>();
			//parse the line for accepting states
			Scanner temp = new Scanner(line);
			while(temp.hasNext())
			acceptingState.add(temp.nextInt());
			temp.close();
	ArrayList<Node> nodes = new ArrayList<Node>();
	//get the alphabet?
	String tempLine = input.nextLine();
	String alphabet = tempLine.substring(tempLine.indexOf(":"+1));
	alphabet = alphabet.trim();
	String[] alpha = alphabet.split("");
	//grab state input
	for(int i =0; i < states; i++)
	{
		Node state = new Node();
		if(acceptingState.contains(i))
			state.accepts = true;
		else
			state.accepts = false;

		state.nodeNumber = i + 1;
		//reuse line and temp cause why not
		line = input.nextLine(); 
		for(int j =0; input.hasNext(); j++)
		{
			state.map.put(alpha[j], input.next());	
		}
		nodes.add(state);
	}
	printNodes(nodes);
	}

	public static void printNodes(ArrayList<Node> nodes)
	{
		for(Node node : nodes)
		{
		System.out.println(node.nodeNumber + ": " + node.accepts);
		}
	
	}
}
