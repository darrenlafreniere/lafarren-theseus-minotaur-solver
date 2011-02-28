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
	/**
	 * Represents a method by which to control an agent. In order to work with
	 * the Solver, Controller implementations must never cache their agent's
	 * positional data, and must instead retrieve it as needed from the Maze.
	 */
	public interface Controller
	{
		/**
		 * Destroys this controller and its members.
		 */
		function destroy():void;
		
		/**
		 * Deeply clones this Controller instance if the implementation
		 * supports it.
		 * @param	game The Game instance that the clone should operate on,
		 * 			if different than this Controller's Game. If left null,
		 * 			this Controller's own Game is used.
		 * @return	A newly cloned Controller instance, or null if the
		 * 			implementation doesn't support cloning.
		 */
		function clone(game:Game = null):Controller;
		
		/**
		 * Returns the agent corresponding to this controller.
		 */
		function get agent():EntityType;
		
		/**
		 * Determines and returns the controllers desired MoveType for its
		 * agent. If this method returns null, it will be polled again on the
		 * next render
		 * frame.
		 * @return	The MoveType that the controller wants to make, or
		 * 			null if the controller hasn't yet determined its move.
		 */
		function determineMoveType():MoveType;
		
		/**
		 * Called after determineMoveType returns a valid MoveType, and the
		 * move wasn't blocked by a wall, and the agent moved.
		 * @param	moveType The MoveType used to move the agent.
		 */
		function onMoved(moveType:MoveType):void;
		
		/**
		 * Called after determineMoveType returns a null MoveType, or after
		 * determineMoveType returns a valid MoveType that was blocked by a
		 * wall.
		 * @param	moveType The MoveType that failed to move the agent.
		 */
		function onMoveFailed(moveType:MoveType):void;
	}
}
