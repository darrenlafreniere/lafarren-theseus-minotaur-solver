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
	import com.lafarren.tmmaze.core.Controller;
	import com.lafarren.tmmaze.core.EntityType;
	import com.lafarren.tmmaze.core.Game;
	import com.lafarren.tmmaze.core.GameEvent;
	import com.lafarren.tmmaze.core.MoveType;
	
	// INTERNAL PACKAGE CLASS
	//
	// Simple Theseus controller that uses whatever MoveType it was told to.
	internal class TheseusDrone implements Controller
	{
		private var m_moveType:MoveType;
		private var m_index:int;
		private var m_moved:Boolean;
		
		/**
		 * @inheritDoc
		 */
		public function destroy():void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function clone(game:Game = null):Controller
		{
			// Not supported
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get agent():EntityType
		{
			return EntityType.THESEUS;
		}
		
		/**
		 * @inheritDoc
		 */
		public function determineMoveType():MoveType
		{
			m_moved = false;
			return m_moveType;
		}
		
		/**
		 * @inheritDoc
		 */
		public function onMoved(moveType:MoveType):void
		{
			m_moved = true;
		}
		
		/**
		 * @inheritDoc
		 */
		public function onMoveFailed(moveType:MoveType):void
		{
			m_moved = false;
		}
		
		/**
		 * The moveType that will be used for the next determineMoveType call.
		 */
		public function get moveType():MoveType
		{
			return m_moveType;
		}
		
		public function set moveType(moveType:MoveType):void
		{
			m_moveType = moveType;
		}
		
		public function get moved():Boolean
		{
			return m_moved;
		}
	}
}
