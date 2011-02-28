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
package com.lafarren.tmmaze.controller
{
	import com.lafarren.tmmaze.core.EntityType;
	import com.lafarren.tmmaze.core.Controller;
	import com.lafarren.tmmaze.core.Game;
	import com.lafarren.tmmaze.core.Maze;
	import com.lafarren.tmmaze.core.MoveType;
	import com.lafarren.tmmaze.core.PointInt;
	import flash.geom.Point;
	
	public class Minotaur implements Controller
	{
		private var m_game:Game;
		
		public function Minotaur(game:Game)
		{
			m_game = game;
		}
		
		/**
		 * @inheritDoc
		 */
		public function clone(game:Game = null):Controller
		{
			return new Minotaur(game ? game : m_game);
		}
		
		/**
		 * @inheritDoc
		 */
		public function destroy():void
		{
			// Nothing to do
		}
		
		/**
		 * @inheritDoc
		 */
		public function get agent():EntityType
		{
			return EntityType.MINOTAUR;
		}
		
		/**
		 * @inheritDoc
		 */
		public function determineMoveType():MoveType
		{
			var moveType:MoveType = null;
			
			const maze:Maze = m_game.maze;
			const theseus:PointInt = maze.getEntityPosition(EntityType.THESEUS);
			const minotaur:PointInt = maze.getEntityPosition(EntityType.MINOTAUR);
			const delta:PointInt = theseus.subtract(minotaur);
			
			// Try to gain on Theseus horizontally
			if (delta.x < 0 && maze.isMoveOpen(minotaur.x, minotaur.y, MoveType.LEFT))
			{
				moveType = MoveType.LEFT;
			}
			else if (delta.x > 0 && maze.isMoveOpen(minotaur.x, minotaur.y, MoveType.RIGHT))
			{
				moveType = MoveType.RIGHT;
			}
			
			// If no horizontal gain could be made, try to gain on Theseus vertically
			if (!moveType)
			{
				if (delta.y < 0 && maze.isMoveOpen(minotaur.x, minotaur.y, MoveType.UP))
				{
					moveType = MoveType.UP;
				}
				else if (delta.y > 0 && maze.isMoveOpen(minotaur.x, minotaur.y, MoveType.DOWN))
				{
					moveType = MoveType.DOWN;
				}
			}
			
			// If no horizontal or vertical gain could be made, skip this move
			if (!moveType)
			{
				moveType = MoveType.SKIP;
			}
			
			return moveType;
		}
		
		/**
		 * @inheritDoc
		 */
		public function onMoved(moveType:MoveType):void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function onMoveFailed(moveType:MoveType):void
		{
		}
	}
}
