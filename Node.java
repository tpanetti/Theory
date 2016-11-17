import java.util.HashMap;
public class Node
{
	public boolean accepts;
	//link to other states
	public HashMap<String,String> map;
	public int nodeIndex;
	public Node(boolean accepts, HashMap map, int nodeIndex)
	{
		this.accepts = accepts;
		this.map = map;
		this.nodeIndex = nodeIndex;
	}
	public Node(){}
}
