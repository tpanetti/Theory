import java.util.HashMap;
public class Node
{
	public boolean accepts;
	//link to other states
	public HashMap map;
	public int nodeNumber;
	public Node(boolean accepts, HashMap map, int nodeNumber)
	{
		this.accepts = accepts;
		this.map = map;
		this.nodeNumber = nodeNumber;
	}
	public Node(){}






}
