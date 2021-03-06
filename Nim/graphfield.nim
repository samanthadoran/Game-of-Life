import math, hashes, sets, Tables

type
  Point* = object
    x*: int
    y*: int
  State* = tuple[current: bool, future: bool]
  NodeObj = object
    state*: State
    #Using 20 to assume no polygons over 20 sides
    neighbours*: array[20, Node]
    position*: Point
  Node* = ref NodeObj

proc hash*(p: Point): Hash =
  result = p.x.hash !& p.y.hash
  result = !$result

proc `==`*(u: Point, v: Point): bool =
  return (u.x == v.x and u.y == v.y)

proc hash*(n: Node): Hash =
  return hash(n.position)

proc fieldInitWalk(n: var Node, nTable: var Table[Point, Node], width: int,
                  height: int, sides: int, pnt: var Point) =
  #Initialize the field by walking the graph recursively
  #TODO: Replace with iterative to support larger graphs

  #If we've gone out of bounds
  if pnt.x < 0 or pnt.x > width:
    return
  if pnt.y < 0 or pnt.y > height:
    return

  #Make a new node
  new(n)

  n.state.current = if random(2) == 1: true else: false
  n.state.future = false

  n.position = pnt
  nTable[n.position] = n

  var tempPoint: Point

  #Get the angle of the 'circle' pointing at the circumfrence
  let interiorAngle: float = PI - ((sides - 2) * 180 / sides) * (PI / 180)

  for angleNum in 0..<sides:
    discard """
    The position of each polygon can be determined by moving about the vertices
    as they lie on a circle
    """
    tempPoint = pnt
    tempPoint.x += round(cos(angleNum.toFloat * interiorAngle) * 4)
    tempPoint.y += round(sin(angleNum.toFloat * interiorAngle) * 4)

    #If the node hasn't been created,
    if not nTable.hasKey(tempPoint):
      #Create it
      fieldInitWalk(n.neighbours[angleNum], nTable, width, height, sides, tempPoint)
    else:
      #Otherwise, properly assign it as a neighbour
      n.neighbours[angleNum] = nTable[tempPoint]

proc initRandomField*(width: int, height: int, sides: int): Node =
  #Helper function to init the field
  randomize()

  var p: Point
  p.x = 0
  p.y = 0

  var nTable: Table[Point, Node] = initTable[Point, Node]()

  fieldInitWalk(result, nTable, cast[int](width), cast[int](height), sides, p)

proc sumSelfAndNeighbours*(n: Node): int =
  #Returns the sum of states of neighbouring nodes and self
  if n == nil:
    return 0
  else:
    result = if n.state.current: 1 else: 0

  for i in 0..<len(n.neighbours):
    if n.neighbours[i] != nil:
      if n.neighbours[i].state.current:
        result += 1

proc step(n: var Node, nSet: var HashSet[Node]) =
  #Recursively shift the future state into current through graph
  n.state.current = n.state.future
  n.state.future = false

  nSet.incl(n)

  for i in 0..<len(n.neighbours):
    if n.neighbours[i] != nil:
      if not nSet.contains(n.neighbours[i]):
        step(n.neighbours[i], nSet)

proc step*(n: var Node) =
  #Helper function to change states
  var nSet: HashSet[Node] = initSet[Node]()
  step(n, nSet)

proc logic*(n: var Node, rules: proc(n: var Node, nSet: var HashSet[Node])) =
  #Helper function to accept arbitrary rules to operate on the nodes
  var nSet: HashSet[Node] = initSet[Node]()
  rules(n, nSet)
