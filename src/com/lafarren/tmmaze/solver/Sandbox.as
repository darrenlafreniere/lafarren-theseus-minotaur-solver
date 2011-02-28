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
	import com.lafarren.tmmaze.core.Maze;
	import com.lafarren.tmmaze.core.MazeDefinition;
	import com.lafarren.tmmaze.core.MoveType;
	import com.lafarren.tmmaze.core.PointInt;
	
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	
	/**
	 * INTERNAL PACKAGE CLASS
	 * 
	 * Implements a sandbox game and maze space for the solver to work in.
	 * Implements a sandbox game and maze space for the solver to work in.
	 * For performance reasons, this class breaks encapsulation a bit and
	 * both extends the Game class and implements the Maze interface. This
	 * allows the class to cache the often-queried agent success states
	 * after an agent position changes.
	 * 
	 * The sandbox wraps a Maze instance and delegates to it for all static
	 * maze data related methods, and stores its own agent position data,
	 * allowing the solver to directly change those positions as needed.
	 * The wrapped Maze's data will never be modified by this class.
	 */
	internal class Sandbox extends Game implements Maze
	{
		private const ENABLE_ASSERTIONS:Boolean = false;
		
		private var m_wrappedMaze:Maze;
		private var m_entityPositions:Vector.<PointInt>;
		
		// Game game ended and agent success for fast lookups.
		private var m_hasEndedCached:Boolean;
		private var m_hasSucceededTheseusCached:Boolean;
		private var m_hasSucceededMinotaurCached:Boolean;
		
		public function Sandbox(gameSource:Game)
		{
			super(this);
			m_wrappedMaze = gameSource.maze;
			
			if (!gameSource.copyStateTo(this, true))
			{
				throw new Error("Could not copy game state into sandbox!");
			}
			
			const entityCount:int = EntityType.length;
			m_entityPositions = new Vector.<PointInt>(entityCount, true);
			for (var i:int = 0; i < entityCount; ++i)
			{
				m_entityPositions[i] = m_wrappedMaze.getEntityPosition(EntityType.fromOrdinal(i));
			}
			
			updateOutcomeCache();
		}
		
		/**
		 * @inheritDoc
		 */
		// Game override
		public override function hasEnded():Boolean
		{
			return m_hasEndedCached;
		}
		
		/**
		 * @inheritDoc
		 */
		// Game override
		public override function hasSucceeded(agent:EntityType):Boolean
		{
			return (agent == EntityType.THESEUS)
				? m_hasSucceededTheseusCached
				: m_hasSucceededMinotaurCached;
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function get eventDispatcher():EventDispatcher
		{
			// Does not dispatch events.
			return new EventDispatcher();
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function cloneMazeDefinition():MazeDefinition
		{
			return m_wrappedMaze.cloneMazeDefinition();
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function get name():String
		{
			return m_wrappedMaze.name;
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function get numCols():int
		{
			return m_wrappedMaze.numCols;
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function get numRows():int
		{
			return m_wrappedMaze.numRows;
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function isTileInside(col:int, row:int):Boolean
		{
			return m_wrappedMaze.isTileInside(col, row);
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function getHorizontalWall(col:int, row:int):Boolean
		{
			return m_wrappedMaze.getHorizontalWall(col, row);
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function getVerticalWall(col:int, row:int):Boolean
		{
			return m_wrappedMaze.getVerticalWall(col, row);
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function getEntityPosition(entityType:EntityType):PointInt
		{
			return m_entityPositions[entityType.ordinal].clone();
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function getEntityPositionFloat(entityType:EntityType):Point
		{
			return m_entityPositions[entityType.ordinal].toPoint();
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function areEntitiesAtSamePosition(entityTypeA:EntityType, entityTypeB:EntityType):Boolean
		{
			return m_entityPositions[entityTypeA.ordinal].equals(m_entityPositions[entityTypeB.ordinal]);
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function isMoveOpen(col:int, row:int, moveType:MoveType):Boolean
		{
			return m_wrappedMaze.isMoveOpen(col, row, moveType);
		}
		
		/**
		 * @inheritDoc
		 */
		// Maze method
		public function move(agent:EntityType, moveType:MoveType):Boolean
		{
			var result:Boolean = false;
			
			if (ENABLE_ASSERTIONS)
			{
				if (!agent.isAgent)
				{
					throw new Error("Unexpected: Sandbox.move called for a non-agent entity!");
				}
				if (hasEnded())
				{
					throw new Error("Unexpected: Sandbox.move called for an ended game!");
				}
			}
			
			{
				// OPTIMIZATION: assumes that isMoveOpen won't modify position
				var position:PointInt = m_entityPositions[agent.ordinal];
				if (m_wrappedMaze.isMoveOpen(position.x, position.y, moveType))
				{
					position.x += moveType.offsetX;
					position.y += moveType.offsetY;
					updateOutcomeCache();
					result = true;
				}
			}
			
			return result;
		}
		
		/**
		 * Returns a direct reference to the internal entity PointInt position object.
		 * @param	entityType An EntityType reference.
		 * @return a direct reference to the internal entity PointInt position object.
		 */
		public function getEntityPositionRef(entityType:EntityType):PointInt
		{
			return m_entityPositions[entityType.ordinal];
		}
		
		/**
		 * Updates the cached return values for the hasEnded and hasSucceeded
		 * methods. This method MUST be called after positions are manually
		 * updated. This does not happen automatically for the sake of
		 * performance. 
		 */
		public function updateOutcomeCache():void
		{
			// Slight optimization: mazes have many more successful Minotaur
			// paths than successful Theseus paths, so test Minotaur success
			// first.
			m_hasSucceededMinotaurCached = super.hasSucceeded(EntityType.MINOTAUR);
			m_hasSucceededTheseusCached = m_hasSucceededMinotaurCached
				? false
				: super.hasSucceeded(EntityType.THESEUS);
			
			m_hasEndedCached = m_hasSucceededTheseusCached || m_hasSucceededMinotaurCached;
		}
		
		/**
		 * Convenience method. If the sandbox's current agent is not Theseus,
		 * it will be ticked until Theseus is current.
		 */
		public function tickUntilTheseusIsCurrent():void
		{
			while (!hasEnded() && !isCurrentAgent(EntityType.THESEUS))
			{
				tick();
			}
		}
		
		/**
		 * Provides a public means of calling setCurrentAgentProtected.
		 * 
		 * @see Game.setCurrentAgentProtected
		 */
		public function setCurrentAgent(agent:EntityType, numMovesThisTurn:int = 0):void
		{
			super.setCurrentAgentProtected(agent, numMovesThisTurn);
		}
	}
}
