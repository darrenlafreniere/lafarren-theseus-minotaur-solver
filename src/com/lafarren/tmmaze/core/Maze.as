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
	import flash.geom.Point;
	
	/**
	 * Dispatched when an agent moves within the maze.
	 *
	 * @eventType flash.events.Event.CHANGE
	 */
	[Event(name = "change", type = "flash.events.Event.CHANGE")]
	
	/**
	 * Abstract interface that provides access to a maze's static and dynamic
	 * data, and a move operation to mutate the maze's state.
	 * 
	 * Only the agent positions are mutable. All other data is guaranteed
	 * constant.
	 */
	public interface Maze
	{
		/**
		 * Destroys this maze and its members.
		 */
		function destroy():void;
		
		/**
		 * Returns the event dispatcher for this maze instance.
		 */
		function get eventDispatcher():EventDispatcher;
		
		/**
		 * Returns a clone of this maze's internal MazeDefinition.
		 * @return
		 */
		function cloneMazeDefinition():MazeDefinition;
		
		/**
		 * The name of the maze.
		 */
		function get name():String;
		
		/**
		 * The number of columns in the maze.
		 */
		function get numCols():int;
		
		/**
		 * The number of rows in the maze.
		 */
		function get numRows():int;
		
		/**
		 * Returns true if the tile specified by a row and column is within
		 * the maze. A tile is considered inside if it's within the allowable
		 * row/column range AND it's reachable from Theseus's start position.
		 */
		function isTileInside(col:int, row:int):Boolean;
		
		/**
		 * Returns true if a horizontal wall is present at the specified row
		 * and column, or if the row and column is outside the valid wall range.
		 * @see MazeDefinition MazeDefinition for the proper row and column notation.
		 */
		function getHorizontalWall(col:int, row:int):Boolean;
		
		/**
		 * Returns true if a vertical wall is present at the specified row
		 * and column, or if the row and column is outside the valid wall range.
		 * @see MazeDefinition MazeDefinition for the proper row and column notation.
		 */
		function getVerticalWall(col:int, row:int):Boolean;
		
		/**
		 * Returns an entity's position within the maze.
		 * @param	entityType An EntityType instance.
		 * @return	Entity position within maze.
		 */
		function getEntityPosition(entityType:EntityType):PointInt;
		
		/**
		 * Returns an entity's position within the maze, using a floating
		 * point flash.geom.Point.
		 * @param	entityType An EntityType instance.
		 * @return	Floating point entity position within maze.
		 */
		function getEntityPositionFloat(entityType:EntityType):Point;
		
		/**
		 * Returns true if the entities are at the same integer position.
		 * More efficient than:
		 * 
		 * 		getEntityPosition(entityTypeA).equals(getEntityPosition(entityTypeB))
		 * 
		 * because the test can be made without cloning any points.
		 * 
		 * @param	entityTypeA The first entity used in the test.
		 * @param	entityTypeB The second entity used in the test.
		 * @return true if the entities are at the same integer position.
		 */
		function areEntitiesAtSamePosition(entityTypeA:EntityType, entityTypeB:EntityType):Boolean;
		
		/**
		 * Returns true if an agent can move from a specified tile without
		 * being blocked by a wall.
		 * @param	from The point to originate the test move from.
		 * @param	moveType The MoveType to test.
		 * @return	Returns true if the test move was not blocked.
		 */
		function isMoveOpen(col:int, row:int, moveType:MoveType):Boolean;
		
		/**
		 * Attempts to move the agent from its current position, according to
		 * the move type.
		 * @param	entityType The agent to move.
		 * @param	moveType The MoveType to use for this move.
		 * @return	Returns true if the movement was successful. A move might
		 * fail if a wall blocks the agent, if the game has ended, or any
		 * implementation-dependent rule.
		 */
		function move(agent:EntityType, moveType:MoveType):Boolean;
	}
}
