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
    String[] outAlphabet = outAlph.split("");
    ArrayList<String> homos= new ArrayList<String>();
    while(input.hasNext())
      homos.add(input.nextLine());


    findHomo(nodes);
  }

  public static void findHomo(ArrayList<Node> nodes)
  {

  }

}
