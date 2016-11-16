import java.io.FileNotFoundException;
import java.io.File;
import java.util.Scanner;
import java.util.ArrayList;
import java.util.HashMap;
public class Main
{
	public static void main(String[] args) throws FileNotFoundException
	{
		// for(String arg : args)
			// System.out.println(arg);
		Scanner input = new Scanner(new File(args[0]));
		String line = input.nextLine();
		int states = Integer.parseInt(line.substring(line.indexOf(":") +2));

		// input.nextLine();
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
		tempLine = tempLine.trim();
		String alphabet = tempLine.substring(tempLine.indexOf(":")+1);
		alphabet = alphabet.trim();
		String[] alpha = alphabet.split("");
		System.out.println(alpha.length);
		//grab state input
		//stupid fencepost
		for(int i =0; i < states; i++)
		{
			System.out.println("what line are we on: " + i);
			Node state = new Node();
			if(acceptingState.contains(i))
				state.accepts = true;
			else
				state.accepts = false;

			//I feel like tom sawyer with all these fencepost problems
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
	// printNodes(nodes);
	traverseDFA(nodes,args[1]);



	}
	//LOOKOUT
	//Dan's gonna put the empty string in here, I GUARENTEE IT
	public static void traverseDFA(ArrayList<Node> nodes, String file) throws FileNotFoundException
	{
		Scanner input = new Scanner(new File(file));
		while(input.hasNext())
		{

			Node itr = nodes.get(0); //starting state is always 0 (Thank god)
			String line = input.nextLine();
			// System.out.println("length of string is");
			// System.out.println(line.length());
			line = line.trim();
			String[] str = line.split("");
			// System.out.println(line);
			if(line.length() == 0)
			{
				if(itr.accepts)
					System.out.println("accept");
				else
					System.out.println("reject");
				continue;
			}
			for(String move : str)
			{
				String nextMove = itr.map.get(move);

				itr = getNode(nodes, nextMove);
				if(itr == null)
				{
					//Oh I shoulda thought about this beforehand
					//oh well, set the node to reject and break out of this loop
					itr = new Node();
					itr.accepts = false;
					break;
				}
			}
			if(itr.accepts)
				System.out.println("accept");
			else
				System.out.println("reject");



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


	public static void printNodes(ArrayList<Node> nodes)
	{
		for(Node node : nodes)
		{
		System.out.println(node.nodeIndex + ": " + node.accepts);
		System.out.println(node.map);
		}

	}
}
