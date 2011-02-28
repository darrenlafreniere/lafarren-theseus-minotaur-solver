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
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.utils.getTimer;
	import mx.core.Application;
		
	/**
	 * Implements the Maze interface. Internally stores agent positions in
	 * floating point coordinates and supports "animated" agent movement
	 * between tiles (which is really just a tween). The floating point
	 * positions are converted to their nearest integers where required.
	 * 
	 * @see #MazeDefinition MazeDefinition
	 */
	public class MazeAnimated extends EventDispatcher implements Maze
	{
		public static const MOVE_DURATION_DEFAULT:Number = 0.1;
		
		private var m_mazeDefinition:MazeDefinition;
		private var m_entityPositions:Vector.<Point>;
		
		private var m_moveDuration:Number; // in seconds
		private var m_moveTarget:EntityType;
		private var m_moveStartMs:int; // in milliseconds
		private var m_moveFrom:Point;
		private var m_moveTo:Point;

		/**
		 * Constructs a new maze instance from a MazeDefinition. Theseus and
		 * Minotaur are positioned at their starting positions.
		 * @param	mazeDefinition The MazeDefinition to initialize the maze instance from.
		 */
		public function MazeAnimated(mazeDefinition:MazeDefinition)
		{
			m_mazeDefinition = mazeDefinition.clone();
			
			const entityCount:int = EntityType.length;
			m_entityPositions = new Vector.<Point>(entityCount, true);
			for (var i:int = 0; i < entityCount; ++i)
			{
				m_entityPositions[i] = mazeDefinition.getEntityPosition(EntityType.fromOrdinal(i)).toPoint();
			}
			
			this.moveDuration = MOVE_DURATION_DEFAULT;
			Application.application.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		/**
		 * @inheritDoc
		 */
		public function destroy():void
		{
			Application.application.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			m_mazeDefinition = null;
			m_entityPositions = null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function cloneMazeDefinition():MazeDefinition
		{
			return m_mazeDefinition.clone();
		}
		
		/**
		 * @inheritDoc
		 */
		public function get eventDispatcher():EventDispatcher
		{
			return this;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get name():String
		{
			return m_mazeDefinition.name;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get numCols():int
		{
			return m_mazeDefinition.numCols;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get numRows():int
		{
			return m_mazeDefinition.numRows;
		}
		
		/**
		 * @inheritDoc
		 */
		public function isTileInside(col:int, row:int):Boolean
		{
			return m_mazeDefinition.isTileInside(col, row);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getHorizontalWall(col:int, row:int):Boolean
		{
			return m_mazeDefinition.getHorizontalWall(col, row);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getVerticalWall(col:int, row:int):Boolean
		{
			return m_mazeDefinition.getVerticalWall(col, row);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getEntityPosition(entityType:EntityType):PointInt
		{
			return PointInt.fromPoint(getEntityPositionRef(entityType));
		}
		
		/**
		 * @inheritDoc
		 */
		public function getEntityPositionFloat(entityType:EntityType):Point
		{
			return m_entityPositions[entityType.ordinal].clone();
		}
		
		/**
		 * @inheritDoc
		 */
		public function areEntitiesAtSamePosition(entityTypeA:EntityType, entityTypeB:EntityType):Boolean
		{
			var result:Boolean;
			if (entityTypeA == entityTypeB)
			{
				result = true;
			}
			else
			{
				var positionA:Point = getEntityPositionRef(entityTypeA);
				var positionB:Point = getEntityPositionRef(entityTypeB);
				if (Math.round(positionA.x) == Math.round(positionB.x) &&
					Math.round(positionA.y) == Math.round(positionB.y))
				{
					result = true;
				}
			}
			
			return result;
		}
		
		/**
		 * @inheritDoc
		 */
		public function isMoveOpen(col:int, row:int, moveType:MoveType):Boolean
		{
			return m_mazeDefinition.isMoveOpen(col, row, moveType);
		}
		
		/**
		 * @inheritDoc
		 */
		public function move(agent:EntityType, moveType:MoveType):Boolean
		{
			var result:Boolean = false;
			if (agent.isAgent && !Game.hasEnded(this) && !isAnyoneMoving())
			{
				var from:PointInt = getEntityPosition(agent);
				if (isMoveOpen(from.x, from.y, moveType))
				{
					var to:PointInt = from.addXy(moveType.offsetX, moveType.offsetY);
					if (!from.equals(to))
					{
						m_moveTarget = agent;
						m_moveStartMs = getTimer();
						m_moveFrom = from.toPoint();
						m_moveTo = to.toPoint();
					}
					
					result = true;
				}
			}
			
			return result;
		}
		
		/**
		 * Returns true if any agent is currently moving.
		 * @return true if any agent is currently moving.
		 */
		public function isAnyoneMoving():Boolean
		{
			return isMoving(EntityType.THESEUS) || isMoving(EntityType.MINOTAUR);
		}
		
		/**
		 * Returns true if the agent is currently moving.
		 * @return true if the agent is currently moving.
		 */
		public function isMoving(entityType:EntityType):Boolean
		{
			return m_moveTarget == entityType;
		}
		
		/**
		 * The duration in seconds that a move takes to animate the distance of one tile.
		 */
		public function get moveDuration():Number
		{
			return m_moveDuration;
		}
		
		public function set moveDuration(moveDuration:Number):void
		{
			m_moveDuration = moveDuration;
		}
		
		private function onEnterFrame(event:Event):void
		{
			if (m_moveTarget)
			{
				// Move the agent's position (currently uses linear interpolation)
				
				// Find millisecond delta then convert to seconds
				const dt:Number = (getTimer() - m_moveStartMs) / 1000.0;
				const alpha:Number = (m_moveDuration > 0.0) ? (dt / m_moveDuration) : 1.0;
				
				if (alpha <= 0.0)
				{
					// Snap to m_moveFrom
					setEntityPositionRef(m_moveTarget, m_moveFrom.clone());
				}
				else if (alpha < 1.0)
				{
					var position:Point = new Point();
					position.x = ((m_moveTo.x - m_moveFrom.x) * alpha) + m_moveFrom.x;
					position.y = ((m_moveTo.y - m_moveFrom.y) * alpha) + m_moveFrom.y;
					setEntityPositionRef(m_moveTarget, position);
				}
				else
				{
					// Snap to m_moveTo and null m_moveTarget to finish the movement
					setEntityPositionRef(m_moveTarget, m_moveTo.clone());
					m_moveTarget = null;
				}
			}
		}
		
		private function setEntityPositionRef(entityType:EntityType, position:Point):void
		{
			if (!m_entityPositions[entityType.ordinal].equals(position))
			{
				m_entityPositions[entityType.ordinal] = position;
				if (hasEventListener(Event.CHANGE))
				{
					dispatchEvent(new Event(Event.CHANGE));
				}
			}
		}
		
		private function getEntityPositionRef(entityType:EntityType):Point
		{
			// If the agent is transitioning, use the position it's moving to.
			return (m_moveTarget == entityType)
				? m_moveTo
				: m_entityPositions[entityType.ordinal];
		}
	}
}
