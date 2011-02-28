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
package com.lafarren.tmmaze.core
{
	import flash.events.EventDispatcher;
	
	/**
	 * Dispatched at the beginning of the first game tick.
	 *
	 * @eventType com.lafarren.tmmaze.core.GameEvent.BEGIN
	 */
	[Event(name = "begin", type = "com.lafarren.tmmaze.core.GameEvent.BEGIN")]
	
	/**
	 * Dispatched after a tick that results in the game end.
	 *
	 * @eventType com.lafarren.tmmaze.core.GameEvent.END
	 */
	[Event(name = "end", type = "com.lafarren.tmmaze.core.GameEvent.END")]
	
	/**
	 * Dispatched when the game transitions from uncopyable to copyable.
	 * @eventType com.lafarren.tmmaze.core.GameEvent.COPYABLE
	 */
	[Event(name = "copyable", type = "com.lafarren.tmmaze.core.GameEvent.COPYABLE")]
	
	/**
	 * Encapsulates the logic of the game, and is bound to a single Maze instance.
	 * Also requires agent controller instances, which can be dynamically swapped
	 * in and out at runtime. If an agent doesn't have a controller, the game will
	 * stall until one is set for it.
	 */
	public class Game extends EventDispatcher
	{
		private var m_maze:Maze;
		
		private var m_agentInfoTheseus:AgentInfo;
		private var m_agentInfoMinotaur:AgentInfo;
		private var m_agentInfoCurrent:AgentInfo;
		
		private var m_began:Boolean;
		private var m_interrupted:Boolean;
		private var m_cloneLockCount:int;
		
		public function Game(maze:Maze)
		{
			m_maze = maze;
			
			m_agentInfoTheseus = new AgentInfo(this, EntityType.THESEUS, 1);
			m_agentInfoMinotaur = new AgentInfo(this, EntityType.MINOTAUR, 2);
			m_agentInfoCurrent = m_agentInfoTheseus;
			m_agentInfoCurrent.beginTurn();
			
			m_began = false;
			m_interrupted = false;
		}
		
		/**
		 * Destroys this game, along with the associated maze and controllers.
		 */
		public function destroy():void
		{
			m_agentInfoTheseus.destroy();
			m_agentInfoMinotaur.destroy();
			
			m_agentInfoCurrent = null;
			m_agentInfoMinotaur = null;
			m_agentInfoTheseus = null;
			
			// Special knowledge: the Sandbox class extends Game and implements
			// Maze, using itself as its own m_maze reference. Avoid bad
			// recursion here:
			if (m_maze != this)
			{
				m_maze.destroy();
			}
			m_maze = null;
		}
		
		/**
		 * Returns true if this Game instance is in a stable, copyable state.
		 * Returns false if the Game is in the middle of a tick, for example.
		 * @return true if this Game instance can currently be copied from.
		 */
		public function get copyable():Boolean
		{
			return m_cloneLockCount == 0;
		}
		
		/**
		 * If this Game is copyable, its game state will be copied into the
		 * specified Game instance. Note that the maze reference is not copied.
		 * 
		 * @param	gameDest The destination Game object that is to receive
		 * 			this game's state.
		 * @param	cloneControllers If true, this Game's controllers will
		 * 			be cloned into the destination game. A destination
		 * 			controller reference is left null if this parameter is
		 * 			false, or if the source controller doesn't support cloning.
		 * @return	true if the game state was copied, and false otherwise.
		 */
		public function copyStateTo(gameDest:Game, cloneControllers:Boolean):Boolean
		{
			var result:Boolean = false;
			if (this.copyable &&
				gameDest.m_agentInfoTheseus &&
				gameDest.m_agentInfoMinotaur &&
				gameDest.m_agentInfoCurrent &&
				m_agentInfoTheseus.copyStateTo(gameDest.m_agentInfoTheseus, cloneControllers) &&
				m_agentInfoMinotaur.copyStateTo(gameDest.m_agentInfoMinotaur, cloneControllers))
			{
				gameDest.m_agentInfoCurrent = (m_agentInfoCurrent == m_agentInfoTheseus)
					? gameDest.m_agentInfoTheseus
					: gameDest.m_agentInfoMinotaur;
				
				gameDest.m_began = m_began;
				gameDest.m_interrupted = m_interrupted;
				
				result = true;
			}
			
			return result;
		}
		
		/**
		 * The maze that this game instance is running.
		 */
		public function get maze():Maze
		{
			return m_maze;
		}
		
		/**
		 * Returns the agent's number of moves per turn.
		 * @param	agent The agent to query for moves per turn.
		 * @return the agent's number of moves per turn.
		 */
		public function getNumMovesPerTurn(agent:EntityType):int
		{
			return getAgentInfo(agent).numMovesPerTurn;
		}
		
		/**
		 * Returns the agent's number of moves so far this turn.
		 * @param	agent The agent to query for moves this turn.
		 * @return the agent's number of moves so far this turn.
		 */
		public function getNumMovesThisTurn(agent:EntityType):int
		{
			return getAgentInfo(agent).numMovesThisTurn;
		}
		
		/**
		 * Returns the Controller instance for the entity type.
		 * @param	agent The agent to get the Controller for.
		 * @return	the agent's Controller controller instance, or null.
		 */
		public function getController(agent:EntityType):Controller
		{
			return getAgentInfo(agent).controller;
		}
		
		/**
		 * Sets the Controller instance for its entity type.
		 * @param	agent The agent to set the Controller for.
		 * @param	controller The Controller instance to set for the agent.
		 */
		public function setController(controller:Controller):void
		{
			getAgentInfo(controller.agent).controller = controller;
		}
		
		/**
		 * True if the game's first tick has begun.
		 */
		public function get began():Boolean
		{
			return m_began;
		}
		
		/**
		 * Attempts to progress the game by performing at most one controller
		 * move. Should be called as frequently as possible.
		 */
		public function tick():void
		{
			incrementCloneLock();
			
			// Reset the previous interrupted flag.
			m_interrupted = false;
			
			// For determining event conditions.
			var beganThisTick:Boolean = false;
			var endedThisTick:Boolean = false;
			
			// Dispatch begin event if this is the first tick.
			if (!m_began)
			{
				dispatchEvent(GameEvent.begin(this));
				m_began = true;
				beganThisTick = true;
			}
			
			// If the game isn't ended, request the current agent's
			// controller to move its agent. If a move is made and the
			// agent's turn has ended, prepare the next agent for its
			// turn next tick.
			var ended:Boolean = hasEnded();
			if (!ended && !m_interrupted)
			{
				var controller:Controller = m_agentInfoCurrent.controller;
				if (controller)
				{
					var moveType:MoveType = controller.determineMoveType();
					if (tickMove(moveType))
					{
						if (m_agentInfoCurrent.hasMadeAllMovesForTurn())
						{
							tickIncrementAgent();
						}
					}
				}
				
				ended = hasEnded();
				if (ended)
				{
					endedThisTick = true;
				}
			}
			
			// Dispatch end event if:
			//		- the game ended on this tick, or
			//		- this is the first tick and the game was already in a ended state.
			if (endedThisTick || (beganThisTick && ended))
			{
				dispatchEvent(GameEvent.end(this));
			}
			
			decrementCloneLock();
		}
		
		/**
		 * Returns the entity type whose turn it currently is.
		 * @return the entity type whose turn it currently is.
		 */
		public function getCurrentAgent():EntityType
		{
			return m_agentInfoCurrent.agent;
		}
		
		/**
		 * Returns true if the entity type has the current turn.
		 * @return true if the entity type has the current turn.
		 */
		public function isCurrentAgent(agent:EntityType):Boolean
		{
			return getCurrentAgent() == agent;
		}
		
		/**
		 * Determine if this game has ended.
		 * @return	True if this game has ended, false otherwise.
		 */
		public function hasEnded():Boolean
		{
			return Game.hasEnded(m_maze);
		}
		
		/**
		 * Determine if the agent has succeeded in this Game's Maze.
		 * @param	agent The agent to test success for.
		 * @return	True if the agent has succeeded within this Game's Maze, false otherwise.
		 */
		public function hasSucceeded(agent:EntityType):Boolean
		{
			return Game.hasSucceeded(m_maze, agent);
		}
		
		/**
		 * Given a Maze instance to query positional state from, this method
		 * determines if a game has ended.
		 * @param	maze A Maze instance to pull positional data from.
		 * @return	True if the game has ended, false otherwise.
		 */
		public static function hasEnded(maze:Maze):Boolean
		{
			// Slight optimization: mazes have many more successful Minotaur
			// paths than successful Theseus paths, so test Minotaur success
			// first.
			return hasSucceeded(maze, EntityType.MINOTAUR) || hasSucceeded(maze, EntityType.THESEUS);
		}
		
		/**
		 * Given a Maze instance to query positional state from, this method
		 * determines if the agent has succeeded.
		 * @param	maze A Maze instance to pull positional data from.
		 * @param	agent The agent to test success for.
		 * @return	True if the agent has succeeded within the Maze, false otherwise.
		 */
		public static function hasSucceeded(maze:Maze, agent:EntityType):Boolean
		{
			return (agent == EntityType.THESEUS)
				? maze.areEntitiesAtSamePosition(EntityType.THESEUS, EntityType.EXIT)
				: maze.areEntitiesAtSamePosition(EntityType.MINOTAUR, EntityType.THESEUS);
		}
		
		/**
		 * Forcibly sets the current agent and the number of moves it's
		 * made so far this move. If the number of moves this turn is at
		 * or beyond the number of moves allowed per turn, the agent's
		 * turn will instantly end and the next agent will be made current.
		 * 
		 * This operation interrupts any current game tick, ends the old
		 * current agent's turn. This will occur even when the old agent and
		 * new agent are the same.
		 * @param	agent The new current agent.
		 * @param	numMovesThisTurn The new current agent's number of moves
		 * 			made so far this turn.
		 */
		protected function setCurrentAgentProtected(agent:EntityType, numMovesThisTurn:int = 0):void
		{
			m_interrupted = true;
			
			m_agentInfoCurrent = getAgentInfo(agent);
			m_agentInfoCurrent.beginTurn(numMovesThisTurn);
			if (m_agentInfoCurrent.hasMadeAllMovesForTurn())
			{
				incrementAgent();
			}
		}
		
		// If the tick hasn't been interrupted, this method tries moving the
		// current agent by the MoveType.
		//
		// If the move is successful, Controller.onMoved is called and this
		// method returns true. Otherwise, Controller.onMoveFailed is called
		// and this method returns false.
		private function tickMove(moveType:MoveType):Boolean
		{
			var result:Boolean = false;
			
			var controller:Controller = m_agentInfoCurrent.controller;
			if (controller && !m_interrupted)
			{
				// check m_interrupted again in case a move event response changed agents
				if (moveType && this.maze.move(controller.agent, moveType) && !m_interrupted)
				{
					m_agentInfoCurrent.madeMove();
					controller.onMoved(moveType);
					result = true;
				}
				else
				{
					controller.onMoveFailed(moveType);
					result = false;
				}
			}
			
			return result;
		}
		
		// If the tick hasn't been interrupted, the current agent is incremented.
		private function tickIncrementAgent():void
		{
			if (!m_interrupted)
			{
				incrementAgent();
			}
		}
		
		// Ends the current agent's turn, makes the next agent current, and
		// begins its turn.
		private function incrementAgent():void
		{
			m_agentInfoCurrent.endTurn();
			
			m_agentInfoCurrent = (m_agentInfoCurrent == m_agentInfoTheseus) ? m_agentInfoMinotaur : m_agentInfoTheseus;
			m_agentInfoCurrent.beginTurn();
		}
		
		private function getAgentInfo(agent:EntityType):AgentInfo
		{
			var result:AgentInfo = null
			switch (agent)
			{
				case EntityType.THESEUS:
					result = m_agentInfoTheseus;
				break;
				
				case EntityType.MINOTAUR:
					result = m_agentInfoMinotaur;
				break;
			}
			
			return result;
		}
		
		private function incrementCloneLock():void
		{
			++m_cloneLockCount;
		}
		
		private function decrementCloneLock():void
		{
			--m_cloneLockCount;
			if (m_cloneLockCount < 0)
			{
				throw new Error("Game.decrementCloneLock called without matching incrementCloneLock call");
			}
			else if (m_cloneLockCount == 0)
			{
				dispatchEvent(GameEvent.copyable(this));
			}
		}
	}
}

import com.lafarren.tmmaze.core.EntityType;
import com.lafarren.tmmaze.core.Controller;
import com.lafarren.tmmaze.core.Game;
import com.lafarren.tmmaze.core.GameEvent;

//
// Internal class for binding agent related info within the game
//
internal class AgentInfo
{
	private var m_game:Game;
	private var m_agent:EntityType;
	private var m_numMovesPerTurn:int;
	private var m_numMovesThisTurn:int;
	private var m_controller:Controller;
	
	public function AgentInfo(game:Game, agent:EntityType, numMovesPerTurn:int):void
	{
		m_game = game;
		m_agent = agent;
		m_numMovesPerTurn = Math.max(numMovesPerTurn, 1);
	}
	
	public function destroy():void
	{
		if (m_controller)
		{
			m_controller.destroy();
			m_controller = null;
		}
	}
	
	// See Game.copyStateTo for more info. Does not copy game reference.
	public function copyStateTo(agentInfoDest:AgentInfo, cloneController:Boolean):Boolean
	{
		agentInfoDest.m_agent = m_agent;
		agentInfoDest.m_numMovesPerTurn = m_numMovesPerTurn;
		agentInfoDest.m_numMovesThisTurn = m_numMovesThisTurn;
		agentInfoDest.m_controller = (cloneController && m_controller)
			? m_controller.clone(agentInfoDest.m_game)
			: null;
		
		return true;
	}
	
	public function get agent():EntityType
	{
		return m_agent;
	}
	
	public function get numMovesPerTurn():int
	{
		return m_numMovesPerTurn;
	}

	// Returns the number of times madeMove() has been called since the last
	// beginTurn() call.
	public function get numMovesThisTurn():int
	{
		return m_numMovesThisTurn;
	}
	
	public function get controller():Controller
	{
		return m_controller;
	}
	
	public function set controller(controller:Controller):void
	{
		m_controller = controller;
	}
	
	// Resets the number of moves made this turn to zero.
	public function beginTurn(numMovesThisTurn:int = 0):void
	{
		m_numMovesThisTurn = numMovesThisTurn;
	}
	
	// Increments the number of moves made this turn.
	public function madeMove():void
	{
		++m_numMovesThisTurn;
	}
	
	// Returns true if the number of moves made this turn is equal to or has
	// exceeded the number of allowed per turn.
	public function hasMadeAllMovesForTurn():Boolean
	{
		return (m_numMovesThisTurn >= m_numMovesPerTurn);
	}
	
	public function endTurn():void
	{
	}
}
