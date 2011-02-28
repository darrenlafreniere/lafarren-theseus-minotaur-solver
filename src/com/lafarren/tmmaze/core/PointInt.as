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
	import flash.geom.Point;
	/**
	 * Similar to flash.geom.Point, but the coordinates are stored as integers.
	 */
	public class PointInt
	{
		private var m_x:int;
		private var m_y:int;
		
		public function PointInt(x:int = 0, y:int = 0)
		{
			m_x = x;
			m_y = y;
		}
		
		public function clone():PointInt
		{
			return new PointInt(m_x, m_y);
		}
		
		public function get x():int
		{
			return m_x;
		}
		
		public function set x(x:int):void
		{
			m_x = x;
		}
		
		public function get y():int
		{
			return m_y;
		}
		
		public function set y(y:int):void
		{
			m_y = y;
		}
		
		/**
		 * Determines whether two points are equal. Two points are equal if they have the same x and y values. 
		 * @param	other The point to be compared. 
		 * @return	A value of true if the object is equal to this Point object; false if it is not equal. 
		 */
		public function equals(toCompare:PointInt):Boolean
		{
			return (toCompare && m_x == toCompare.m_x && m_y == toCompare.m_y);
		}
		
		/**
		 * Adds the coordinates of another point to the coordinates of this point to create a new point. 
		 * @param	v The point to be added.
		 * @return	The new point.
		 */
		public function add(v:PointInt):PointInt
		{
			var result:PointInt = new PointInt(m_x, m_y);
			
			result.m_x += v.m_x;
			result.m_y += v.m_y;
			
			return result;
		}
		
		/**
		 * Adds the x & y coordinates to the coordinates of this point to create a new point. 
		 * @param	v The point to be added.
		 * @return	The new point.
		 */
		public function addXy(deltaX:int, deltaY:int):PointInt
		{
			var result:PointInt = new PointInt(m_x, m_y);
			
			result.m_x += deltaX;
			result.m_y += deltaY;
			
			return result;
		}
		
		/**
		 * Subtracts the coordinates of another point from the coordinates of this point to create a new point. 
		 * @param	v The point to be subtracted from this.
		 * @return	The new point.
		 */
		public function subtract(v:PointInt):PointInt
		{
			var result:PointInt = new PointInt(m_x, m_y);
			
			result.m_x -= v.m_x;
			result.m_y -= v.m_y;
			
			return result;
		}
		
		public static function fromPoint(point:Point):PointInt
		{
			return new PointInt(Math.round(point.x), Math.round(point.y));
		}
		
		public function toPoint():Point
		{
			return new Point(m_x, m_y);
		}
	}
}
