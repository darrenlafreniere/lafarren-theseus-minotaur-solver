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
	import flash.geom.Point;
	import flash.utils.getTimer;
	import flash.utils.Dictionary;
	
	import com.lafarren.tmmaze.core.EntityType;
	import com.lafarren.tmmaze.core.Game;
	import com.lafarren.tmmaze.core.GameEvent;
	import com.lafarren.tmmaze.core.MoveType;
	import com.lafarren.tmmaze.core.PointInt;
	
	/**
	 * Solves a Game from its current state, possibly over several time sliced
	 * ticks. Solves using A&#42;, where each unique node's identity is based
	 * on both agents' positions, rather than just Theseus.
	 */
	public class Solver
	{
		// MoveType.vector clones its own internal vector. To avoid creating
		// clones for each MoveType iteration, cache our own copy.
		private static const MOVE_TYPES:Vector.<MoveType> = MoveType.vector;
		
		private var m_timeSliceMilliseconds:int;
		private var m_sandbox:Sandbox;
		private var m_theseusDrone:TheseusDrone;
		private var m_exit:PointInt;
		
		private var m_nodes:Dictionary;
		private var m_openListHead:Node;
		private var m_closedSet:Dictionary;
		
		private var m_solutionPath:Vector.<MoveType>;
		private var m_failed:Boolean;
		
		/**
		 * Constructs a solver for the specified Game instance.
		 * @param	game The Game instance to solve. Will not be modified.
		 * @param	timeSliceSeconds The duration of each tick's time slice.
		 */
		public function Solver(game:Game, timeSliceSeconds:Number)
		{
			try
			{
				Node.validateGame(game);
			}
			catch (error:Error)
			{
				m_failed = true;
				throw error;
			}
			
			m_timeSliceMilliseconds = Math.max(int(timeSliceSeconds * 1000.0), 1);
			init(game);
		}
		
		/**
		 * Destroys this solver and its members.
		 */
		public function destroy():void
		{
			// m_sandbox could be null if Theseus or the Minotaur had already
			// succeeded when the Solver was created and initialized.
			if (m_sandbox != null)
			{
				m_sandbox.destroy();
			}
			
			m_sandbox = null;
			m_theseusDrone = null;
			m_exit = null;
			m_nodes = null;
			m_openListHead = null;
			m_closedSet = null;
			m_solutionPath = null;
		}
		
		/**
		 * Executes a time slice of the solver's execution until the solver
		 * has completed, or the time slice is used up.
		 */
		public function executeTimeSlice():void
		{
			if (m_sandbox && !this.completed)
			{
				var tickStartTime:int = getTimer();
				do
				{
					tick();
				}
				while (!this.completed && (getTimer() - tickStartTime) < m_timeSliceMilliseconds);
			}
		}
		
		/**
		 * True if the solver has finished evaluating, and has either
		 * succeeded or failed in finding a solution.
		 */
		public function get completed():Boolean
		{
			return this.succeeded || this.failed;
		}
		
		/**
		 * True if the solver has succeeded in finding a solution.
		 */
		public function get succeeded():Boolean
		{
			return m_solutionPath != null;
		}
		
		/**
		 * True if the solver has failed in finding a solution.
		 */
		public function get failed():Boolean
		{
			return m_failed;
		}
		
		/**
		 * The solution path if the solver has succeeded, and null otherwise.
		 */
		public function get solutionPath():Vector.<MoveType>
		{
			return m_solutionPath ? m_solutionPath.concat() : null;
		}
		
		private function onGameCopyable(event:GameEvent):void
		{
			event.game.removeEventListener(GameEvent.COPYABLE, onGameCopyable);
			init(event.game);
		}
		
		private function init(game:Game):void
		{
			// If the game is not currently copyable, register for when it
			// becomes copyable so we can try initializing the sandbox again.
			if (!game.copyable)
			{
				game.addEventListener(GameEvent.COPYABLE, onGameCopyable);
			}
			else
			{
				if (game.hasSucceeded(EntityType.THESEUS))
				{
					m_solutionPath = new Vector.<MoveType>();
				}
				else if (game.hasSucceeded(EntityType.MINOTAUR))
				{
					m_failed = true;
				}
				else
				{
					m_sandbox = new Sandbox(game);
					m_theseusDrone = new TheseusDrone();
					m_sandbox.setController(m_theseusDrone);
					m_sandbox.tickUntilTheseusIsCurrent();
					m_exit = m_sandbox.getEntityPosition(EntityType.EXIT);
					
					m_nodes = new Dictionary();
					m_closedSet = new Dictionary;
					
					var node:Node = getOrCreateNodeFromSandboxState();
					node.updateParentAndHeuristic(null, m_exit);
					addToOpenList(node);
				}
			}
		}
		
		private function tick():void
		{
			if (m_openListHead)
			{
				var node:Node = m_openListHead;
				if (node.theseusX == m_exit.x && node.theseusY == m_exit.y)
				{
					// Success, construct path
					m_solutionPath = node.createPath();
				}
				else
				{
					var successors:Vector.<Node> = getOrCreateSuccessors(node);
					for (var i:int = 0, n:int = successors.length; i < n; i++)
					{
						var successor:Node = successors[i];
						
						var newG:Number = Node.computeG(node, successor);
						var isOpen:Boolean = isInOpenList(successor);
						var isClosed:Boolean = isInClosedSet(successor);
						
						// If the node is not on either the open list of the
						// closed set, or its current cost is greater than the
						// new cost, evaluate it.
						if (!(isOpen || isClosed) || successor.g > newG)
						{
							successor.updateParentAndHeuristic(node, m_exit);
							if (isClosed)
							{
								removeFromClosedSet(successor);
							}
							if (!isOpen)
							{
								addToOpenList(successor);
							}
						}
					}
					
					addToClosedSet(node);
				}
			}
			else
			{
				m_failed = true;
			}
		}
		
		// Sets the agent positions from the node, sets Theseus as the current
		// agent, and updates the sandbox's outcome.
		private function setSandboxStateFromNode(node:Node):void
		{
			var theseus:PointInt = m_sandbox.getEntityPositionRef(EntityType.THESEUS);
			var minotaur:PointInt = m_sandbox.getEntityPositionRef(EntityType.MINOTAUR);
			theseus.x = node.theseusX;
			theseus.y = node.theseusY;
			minotaur.x = node.minotaurX;
			minotaur.y = node.minotaurY;
			
			m_sandbox.setCurrentAgent(EntityType.THESEUS, node.theseusNumMovesThisTurn);
			m_sandbox.updateOutcomeCache();
		}
		
		private function getOrCreateNodeFromSandboxState():Node
		{
			var theseusNumMovesThisTurn:int = m_sandbox.getNumMovesThisTurn(EntityType.THESEUS);
			var theseus:PointInt = m_sandbox.getEntityPositionRef(EntityType.THESEUS);
			var minotaur:PointInt = m_sandbox.getEntityPositionRef(EntityType.MINOTAUR);
			return getOrCreateNode(theseusNumMovesThisTurn, theseus.x, theseus.y, minotaur.x, minotaur.y);
		}
		
		private function getOrCreateNode(theseusNumMovesThisTurn:int, theseusX:int, theseusY:int, minotaurX:int, minotaurY:int):Node
		{
			var node:Node = null;
			
			const key:uint = Node.makeKey(theseusNumMovesThisTurn, theseusX, theseusY, minotaurX, minotaurY);
			node = m_nodes[key];
			if (!node)
			{
				node = new Node(key);
				m_nodes[key] = node;
			}
			
			return node;
		}
		
		private function getOrCreateSuccessors(node:Node):Vector.<Node>
		{
			var result:Vector.<Node> = new Vector.<Node>();
			
			var key:uint = node.key;
			var theseus:PointInt = m_sandbox.getEntityPositionRef(EntityType.THESEUS);
			var minotaur:PointInt = m_sandbox.getEntityPositionRef(EntityType.MINOTAUR);
			for (var i:int = 0, n:int = MOVE_TYPES.length; i < n; ++i)
			{
				// Reset the sandbox from the node's state to try this move.
				setSandboxStateFromNode(node);
				
				// Set the TheseusDrone Controller's next move, tick the sandbox,
				// and evaluate the outcome.
				m_theseusDrone.moveType = MOVE_TYPES[i];
				m_sandbox.tick();
				
				if (m_theseusDrone.moved)
				{
					// If Theseus just made his last move, tick the sandbox
					// through the Minotaur's turn to capture its response.
					if (m_sandbox.isCurrentAgent(EntityType.MINOTAUR))
					{
						m_sandbox.tickUntilTheseusIsCurrent()
					}
					
					// Continue inspecting this move if the Minotaur hasn't succeeded.
					if (!m_sandbox.hasSucceeded(EntityType.MINOTAUR))
					{
						var successor:Node = getOrCreateNodeFromSandboxState();
						
						// Continue inspecting this move if the the successor is not the
						// same as the parent (i.e., no one moved).
						if (node != successor)
						{
							// Add the successor to the results.
							result.push(successor);
							
							// Continue evaluating unless Theseus has succeeded.
							if (m_sandbox.hasSucceeded(EntityType.THESEUS))
							{
								break;
							}
						}
					}
				}
			}
			
			return result;
		}
		
		private function addToOpenList(node:Node):void
		{
			// Even if the node is already on the open list, remove and re-add
			// it to ensure proper sorting.
			removeFromOpenList(node);
			removeFromClosedSet(node);
			
			var f:Number = node.f;
			var prev:Node = null;
			var next:Node = m_openListHead;
			while (next && next.f < f)
			{
				prev = next;
				next = next.openListNext;
			}
			
			// Set links from node to prev and next
			node.openListPrev = prev;
			node.openListNext = next;
			
			// Set link from prev or head to node
			if (prev)
			{
				prev.openListNext = node;
			}
			else
			{
				m_openListHead = node;
			}
			
			// Set link from next to node
			if (next)
			{
				next.openListPrev = node;
			}
		}
		
		private function removeFromOpenList(node:Node):void
		{
			if (isInOpenList(node))
			{
				// Remove links from node to prev and next
				var prev:Node = node.openListPrev;
				var next:Node = node.openListNext;
				node.openListPrev = null;
				node.openListNext = null;
				
				// Set link from prev to next
				if (prev)
				{
					prev.openListNext = next;
				}
				else
				{
					m_openListHead = next;
				}
				
				// Set link from next to prev
				if (next)
				{
					next.openListPrev = prev;
				}
			}
		}
		
		private function isInOpenList(node:Node):Boolean
		{
			return node.openListPrev || node.openListNext || m_openListHead == node;
		}
		
		private function addToClosedSet(node:Node):void
		{
			if (!isInClosedSet(node))
			{
				removeFromOpenList(node);
				m_closedSet[node.key] = node;
			}
		}
		
		private function removeFromClosedSet(node:Node):void
		{
			if (isInClosedSet(node))
			{
				delete m_closedSet[node.key];
			}
		}
		
		private function isInClosedSet(node:Node):Boolean
		{
			return m_closedSet[node.key] != null;
		}
	}
}
