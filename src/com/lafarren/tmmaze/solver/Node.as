//
// Copyright 2010, Darren Lafreniere
// <http://www.lafarren.com/theseus-minotaur-solver/>
// 
// This file is part of lafarren.com's Theseus and Minotaur Maze Solver,
// or tmmaze-solver.
// 
// tmmaze-solver is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// tmmaze-solver is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with tmmaze-solver, named License.txt. If not, see
// <http://www.gnu.org/licenses/>.
//
package com.lafarren.tmmaze.solver
{
	import com.lafarren.tmmaze.core.EntityType;
	import com.lafarren.tmmaze.core.Game;
	import com.lafarren.tmmaze.core.MoveType;
	import com.lafarren.tmmaze.core.PointInt;
	
	/**
	 * INTERNAL PACKAGE CLASS
	 * 
	 * A game state node within the solver's A* search space.
	 * @see Solver
	 */
	internal class Node
	{
		// Node key and game state bit packing:
		//
		//	uint:
		//		bits 31 - 28 [4 bits]: Theseus's numMovesThisTurn
		//		bits 27 - 21 [7 bits]: Theseus's x
		//		bits 20 - 14 [7 bits]: Theseus's y
		//		bits 13 -  7 [7 bits]: Minotaur's x
		//		bits  6 -  0 [7 bits]: Minotaur's y
		//
		// The Minotaur's numMovesThisTurn need not be saved, because on
		// initialization and successor creation, the solver ticks its sandbox
		// until Theseus is the current controller. There will never exist a Node
		// that describes the game's state in the middle of a Minotaur turn.
		//
		// This bit allotment is enforced by the following constants:
		private static const AGENT_COORDINATE_BITS:int  = 7;
		private static const THESEUS_MOVES_BITS:int     = 4;
		
		private static const AGENT_COORDINATE_MASK:int  = (1 << AGENT_COORDINATE_BITS) - 1;
		private static const THESEUS_MOVES_MASK:int     = (1 << THESEUS_MOVES_BITS) - 1;
		
		private static const MINOTAUR_Y_SHIFT:int       = AGENT_COORDINATE_BITS * 0;
		private static const MINOTAUR_X_SHIFT:int       = AGENT_COORDINATE_BITS * 1;
		private static const THESEUS_Y_SHIFT:int        = AGENT_COORDINATE_BITS * 2;
		private static const THESEUS_X_SHIFT:int        = AGENT_COORDINATE_BITS * 3;
		private static const THESEUS_MOVES_SHIFT:int    = AGENT_COORDINATE_BITS * 4;
		
		private static const MAZE_SIZE_MAX:int          = AGENT_COORDINATE_MASK;
		private static const THESEUS_MOVES_MAX:int      = THESEUS_MOVES_MASK;
		
		// This penalty is added to g for a change of Theseus's direction. Just
		// enough to prevent unnecessary stair-stepping movement.
		private static const DIRECTION_CHANGE_PENALTY:Number = 0.1;
		
		// The agents' positions are byte-packed into the key.
		private var m_key:uint;
		
		private var m_parent:Node;
		
		// Heuristic properties. In A* notation:
		//		- g is the current cost for reaching this node
		//		- h is the naive best-case cost estimate from this node to the exit
		//		- f is sum of g and h
		private var m_g:Number;
		private var m_h:Number;
		private var m_f:Number;
		
		// Open list links. Node need to encapsulate since the Node class itself
		// never touches these.
		public var openListPrev:Node;
		public var openListNext:Node;
		
		// Throws an error if the game's properties cannot be supported by the
		// solver's Node class.
		public static function validateGame(game:Game):void
		{
			// Validate the maze's size against what this solver supports.
			if (game.maze.numCols > MAZE_SIZE_MAX || game.maze.numRows > MAZE_SIZE_MAX)
			{
				throw new Error
				(
					"Maze " +
					"(size: " + game.maze.numCols + "x" + game.maze.numRows + ") " +
					"has a larger dimension than is supported by this solver " +
					"(max size: " + MAZE_SIZE_MAX + "x" + MAZE_SIZE_MAX + ")"
				);
			}
			
			// Validate the game's number of Theseus moves per turn against what this
			// solver supports.
			if (game.getNumMovesPerTurn(EntityType.THESEUS) > THESEUS_MOVES_MAX)
			{
				throw new Error
				(
					"Theseus's moves per turn (" + game.getNumMovesPerTurn(EntityType.THESEUS) + ")" +
					"is greater than from the moves per turn supported by this solver " +
					"(" + THESEUS_MOVES_MAX + ")"
				);
			}
		}
		
		// Makes a dictionary key from the agents' positions.
		// MAZE_SIZE_MAX ensures that valid maze coordinates are packable.
		public static function makeKey(theseusNumMovesThisTurn:int, theseusX:int, theseusY:int, minotaurX:int, minotaurY:int):uint
		{
			return (
				(theseusNumMovesThisTurn << THESEUS_MOVES_SHIFT) |
				(theseusX << THESEUS_X_SHIFT) |
				(theseusY << THESEUS_Y_SHIFT) |
				(minotaurX << MINOTAUR_X_SHIFT) |
				(minotaurY << MINOTAUR_Y_SHIFT));
		}
		
		public static function computeG(parent:Node, child:Node):Number
		{
			var result:Number = 0;
			if (parent)
			{
				// Assume parent horizontally or vertically one tile away from child
				result = parent.m_g + 1;
				
				// Add slight penalty for change of direction
				var grandparent:Node = parent.parent;
				if (grandparent)
				{
					const dx1:int = parent.theseusX - grandparent.theseusX;
					const dx2:int = child.theseusX - parent.theseusX;
					if (dx1 != dx2)
					{
						const dy1:int = parent.theseusY - grandparent.theseusY;
						const dy2:int = child.theseusY - parent.theseusY;
						if (dy1 != dy2)
						{
							result += DIRECTION_CHANGE_PENALTY;
						}
					}
				}
			}
			
			return result;
		}
		
		public function Node(key:uint)
		{
			m_key = key;
		}
		
		public function updateParentAndHeuristic(parent:Node, exit:PointInt):void
		{
			m_parent = parent;
			
			m_g = computeG(m_parent, this);
			
			// Since Theseus is restricted to 90 degree movements, rather than
			// using a straight-line, as the crow flies distance estimate, add
			// the horizontal and vertical differences between the points for
			// the estimate.
			m_h = Math.abs(exit.x - this.theseusX) + Math.abs(exit.y - this.theseusY);
			
			m_f = m_g + m_h;
		}
		
		public function get key():uint
		{
			return m_key;
		}
		
		public function get theseusNumMovesThisTurn():int
		{
			return (m_key >> THESEUS_MOVES_SHIFT) & THESEUS_MOVES_MASK;
		}
		
		public function get theseusX():int
		{
			return (m_key >> THESEUS_X_SHIFT) & AGENT_COORDINATE_MASK;
		}
		
		public function get theseusY():int
		{
			return (m_key >> THESEUS_Y_SHIFT) & AGENT_COORDINATE_MASK;
		}
		
		public function get minotaurX():int
		{
			return (m_key >> MINOTAUR_X_SHIFT) & AGENT_COORDINATE_MASK;
		}
		
		public function get minotaurY():int
		{
			return (m_key >> MINOTAUR_Y_SHIFT) & AGENT_COORDINATE_MASK;
		}
		
		public function get parent():Node
		{
			return m_parent;
		}
		
		public function get g():Number
		{
			return m_g;
		}
		
		public function get h():Number
		{
			return m_h;
		}
		
		public function get f():Number
		{
			return m_f;
		}
		
		public function createPath():Vector.<MoveType>
		{
			// Build a backwards points vector from this node up through ancestors
			// to the root, then reverse it.
			var points:Vector.<PointInt> = new Vector.<PointInt>();
			{
				var current:Node = this;
				while (current)
				{
					points.push(new PointInt(current.theseusX, current.theseusY));
					current = current.parent;
				}
				
				points.reverse();
			}
			
			// Generate a MoveType vector based on neighboring point offsets.
			var moveTypes:Vector.<MoveType> = new Vector.<MoveType>(points.length - 1);
			for (var i:int = 0, n:int = moveTypes.length; i < n; ++i)
			{
				var from:PointInt = points[i];
				var to:PointInt = points[i + 1];
				moveTypes[i] = MoveType.fromOffsetXy(to.x - from.x, to.y - from.y);
			}
			
			return moveTypes;
		}
	}
}
