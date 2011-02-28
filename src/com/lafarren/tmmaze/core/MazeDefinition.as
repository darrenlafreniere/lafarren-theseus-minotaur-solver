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
	 * <p>
	 * 	Contains a maze's size, wall placement, initial entity positions, and
	 * 	tile data. MazeDefinition instances are mutable and cloneable.
	 * </p>
	 * 
	 * <p>
	 * 	Wall data is queried separately for horizontal and
	 * 	vertical walls, using a (row,column) notation. The relationships
	 * 	between a square tile and its surrounding walls are as follows.
	 * 	Given tile (x, y):
	 * 	<ul>
	 * 		<li>its left wall is:   vertical  (row = y,     column = x)</li>
	 * 		<li>its top wall is:    horizontal(row = y,     column = x)</li>
	 * 		<li>its right wall is:  vertical  (row = y,     column = x + 1)</li>
	 * 		<li>its bottom wall is: horizontal(row = y + 1, column = x)</li>
	 * 	</ul>
	 * </p>
	 */
	public class MazeDefinition
	{
		/**
		 * The maximum number of tile columns in a map, including any exit columns.
		 */
		public static const COLS_MAX:int  = 15;
		
		/**
		 * The maximum number of tile rows in a map, including any exit rows.
		 */
		public static const ROWS_MAX:int = 10;
		
		// Hack that prevents the constructor from initializing default state
		// when it's a clone destination. Relies on the fact that AS3 is single
		// threaded. I wish AS3 supported constructor overloading.
		private static var m_isCloning:Boolean;
		
		private var m_name:String;
		
		// Wall data is stored in two separate 2-dimensional vectors.
		// m_vwalls contains the row-major wall data for the vertical walls.
		// m_hwalls contains the row-major wall data for the horizontal walls.
		// true indicates the presence of a wall, false indicates no wall.
		private var m_hwalls:Vector.<Vector.<Boolean>>;
		private var m_vwalls:Vector.<Vector.<Boolean>>;
		
		private var m_entityPositions:Vector.<PointInt>;
		
		// Stores the "insideness" of each tile in the maze. See the isTileInside
		// method for more info.
		// Changes to the definition set m_tilesInsidenessNeedsRebuild to true,
		// and m_tilesInsideness data is rebuilt lazily on the first read.
		private var m_tilesInsideness:Vector.<Vector.<Boolean>>;
		private var m_tilesInsidenessNeedsRebuild:Boolean = true;
		
		public function MazeDefinition()
		{
			if (!m_isCloning)
			{
				m_name = "";
				
				m_hwalls = new Vector.<Vector.<Boolean>>();
				m_vwalls = new Vector.<Vector.<Boolean>>();
				resize(1, 1);

				// By default, align the entity positions in a row
				const entityCount:int = EntityType.length;
				m_entityPositions = new Vector.<PointInt>(entityCount, true);
				for (var i:int = 0; i < entityCount; ++i)
				{
					m_entityPositions[i] = new PointInt(i, 0);
				}
			}
		}
		
		public function clone():MazeDefinition
		{
			MazeDefinition.m_isCloning = true;
			var result:MazeDefinition = new MazeDefinition();
			MazeDefinition.m_isCloning = false;
			
			result.m_name = m_name;
			
			result.m_hwalls = cloneWallData(m_hwalls);
			result.m_vwalls = cloneWallData(m_vwalls);
			
			const entityCount:int = m_entityPositions.length;
			result.m_entityPositions = new Vector.<PointInt>(entityCount, true);
			for (var i:int = 0; i < entityCount; ++i)
			{
				result.m_entityPositions[i] = m_entityPositions[i].clone();
			}
			
			// NOTE: Don't bother cloning m_tilesInsideness; let it be lazily built on
			// first access.
			if (!result.m_tilesInsidenessNeedsRebuild)
			{
				throw new Error("result.m_tilesInsidenessNeedsRebuild is unexpectedly false");
			}
			
			return result;
		}
		
		/**
		 * The name of the maze.
		 */
		public function get name():String
		{
			return m_name;
		}
		
		/**
		 * The name of the maze.
		 */
		public function set name(name:String):void
		{
			m_name = name;
		}
		
		/**
		 * The number of columns of the maze in tiles.
		 */
		public function get numCols():int
		{
			return (m_hwalls.length > 0) ? m_hwalls[0].length : 0;
		}
		
		/**
		 * The numRows of the maze in tiles.
		 */
		public function get numRows():int
		{
			return m_vwalls.length;
		}
		
		/**
		 * Resizes the maze according to the numCols and numRows, specified in
		 * number of tiles. Shrinking a dimension will retain the existing
		 * wall data, but will not alter the entity positions. Expanding
		 * a dimension will pad the new wall data with false values. Each
		 * dimension is inclusively clamped between 1 and COLS_MAX/ROWS_MAX.
		 * @param	numCols The new maze's number of columns.
		 * @param	numRows The new maze numRows.
		 */
		public function resize(numCols:int, numRows:int):void
		{
			numCols = Math.min(Math.max(1, numCols), COLS_MAX);
			numRows = Math.min(Math.max(1, numRows), ROWS_MAX);
			
			// m_hwalls stores horizontal tile edges, thus the extra row
			var hrowCount:int = numRows + 1;
			var hcolCount:int = numCols;
			resizeWallData(m_hwalls, hrowCount, hcolCount);
			
			// m_vwalls stores vertical tile edges, thus the extra column
			var vrowCount:int = numRows;
			var vcolCount:int = numCols + 1
			resizeWallData(m_vwalls, vrowCount, vcolCount);
			
			m_tilesInsidenessNeedsRebuild = true;
		}
		
		/**
		 * Returns an entity's position.
		 * @param	entityType An EntityType instance.
		 * @return	Entity position within maze.
		 */
		public function getEntityPosition(entityType:EntityType):PointInt
		{
			return m_entityPositions[entityType.ordinal].clone();
		}

		/**
		 * Sets an entity's position.
		 * @param	entityType An EntityType instance.
		 * @param	position Entity position within maze.
		 */
		public function setEntityPosition(entityType:EntityType, position:PointInt):void
		{
			if (!m_entityPositions[entityType.ordinal].equals(position))
			{
				m_entityPositions[entityType.ordinal] = position.clone();
				m_tilesInsidenessNeedsRebuild = true;
			}
		}
		
		/**
		 * Returns true if a horizontal wall is present at the specified row
		 * and column, or if the row and column is outside the valid wall range.
		 */
		public function getHorizontalWall(col:int, row:int):Boolean
		{
			return getWall(m_hwalls, col, row);
		}
		
		/**
		 * Adds or removes a horizontal wall at the specified row and column.
		 */
		public function setHorizontalWall(col:int, row:int, state:Boolean):void
		{
			setWall(m_hwalls, col, row, state);
		}
		
		/**
		 * Returns true if a vertical wall is present at the specified row
		 * and column, or if the row and column is outside the valid wall range.
		 */
		public function getVerticalWall(col:int, row:int):Boolean
		{
			return getWall(m_vwalls, col, row);
		}
		
		/**
		 * Adds or removes a vertical wall at the specified row and column.
		 */
		public function setVerticalWall(col:int, row:int, state:Boolean):void
		{
			setWall(m_vwalls, col, row, state);
		}
		
		/**
		 * Returns true if an agent can move from a specified tile without
		 * being blocked by a wall.
		 * @param	from The point to originate the test move from.
		 * @param	moveType The MoveType to test.
		 * @return	Returns true if the test move was not blocked.
		 */
		public function isMoveOpen(col:int, row:int, moveType:MoveType):Boolean
		{
			var blocked:Boolean = true;
			switch (moveType)
			{
				case MoveType.UP:
					blocked = getHorizontalWall(col, row);
				break;
				case MoveType.DOWN:
					blocked = getHorizontalWall(col, row + 1);
				break;
				case MoveType.LEFT:
					blocked = getVerticalWall(col, row);
				break;
				case MoveType.RIGHT:
					blocked = getVerticalWall(col + 1, row);
				break;
				case MoveType.SKIP:
					blocked = false;
				break;
			}
			
			return !blocked;
		}
		
		/**
		 * Returns true if the tile specified by a row and column is within
		 * the maze. A tile is considered inside if it's within the allowable
		 * row/column range AND it's reachable from Theseus's start position.
		 */
		public function isTileInside(col:int, row:int):Boolean
		{
			var result:Boolean = false;
			if (row >= 0 && col >= 0)
			{
				if (m_tilesInsidenessNeedsRebuild)
				{
					buildTileInsideness();
					m_tilesInsidenessNeedsRebuild = false;
					if (!m_tilesInsideness)
					{
						throw new Error("m_tilesInsideness is null after call to MazeDefinition.buildTileInsideness");
					}
				}
				
				if (row < m_tilesInsideness.length)
				{
					var v:Vector.<Boolean> = m_tilesInsideness[row];
					if (col < v.length)
					{
						result = v[col];
					}
				}
			}
			
			return result;
		}
		
		// Helper method of clone(); deep-copies the source 2-dimensional
		// vector into the destination.
		private function cloneWallData(walls:Vector.<Vector.<Boolean>>):Vector.<Vector.<Boolean>>
		{
			const rowCount:int = walls.length;
			var result:Vector.<Vector.<Boolean>> = new Vector.<Vector.<Boolean>>(rowCount);
			for (var row:int = 0; row < rowCount; ++row)
			{
				result[row] = walls[row].concat();
			}
			
			return result;
		}
		
		// Helper method of resize(); resizes a 2-dimensional vector according
		// to the row count and column count.
		private function resizeWallData(walls:Vector.<Vector.<Boolean>>, rowCount:int, colCount:int):void
		{
			walls.length = rowCount;
			for (var row:int = 0; row < rowCount; ++row)
			{
				if (walls[row])
				{
					walls[row].length = colCount;
				}
				else
				{
					walls[row] = new Vector.<Boolean>(colCount);
				}
			}
		}
		
		// Returns true if a wall is present at the specified row and column,
		// or if the row and column is outside the valid wall range.
		private function getWall(walls:Vector.<Vector.<Boolean>>, col:int, row:int):Boolean
		{
			var result:Boolean = true;
			if (row >= 0 && row < walls.length)
			{
				var v:Vector.<Boolean> = walls[row];
				if (col >= 0 && col < v.length)
				{
					result = v[col];
				}
			}
			
			return result;
		}
		
		// Adds or removes a wall at the specified row and column.
		private function setWall(walls:Vector.<Vector.<Boolean>>, col:int, row:int, state:Boolean):void
		{
			if (walls[row][col] != state)
			{
				walls[row][col] = state;
				m_tilesInsidenessNeedsRebuild = true;
			}
		}
		
		private function buildTileInsideness():void
		{
			// Build the m_tilesInsideness 2-dimensional map. Begin at
			// Theseus's start position and visit every reachable tile,
			// marking each as valid.
			
			// First allocate and initialize the data
			const numCols:int = this.numCols;
			const numRows:int = this.numRows;
			m_tilesInsideness = new Vector.<Vector.<Boolean>>(numRows, true);
			for (var row:int = 0; row < numRows; ++row)
			{
				m_tilesInsideness[row] = new Vector.<Boolean>(numCols, true);
				for (var col:int = 0; col < numCols; ++col)
				{
					m_tilesInsideness[row][col] = false;
				}
			}
			
			// Beginning from Theseus's start position, recursively visit nodes
			buildTileInsidenessVisit(getEntityPosition(EntityType.THESEUS));
		}
		
		private function buildTileInsidenessVisit(tile:PointInt):void
		{
			if
			(
				tile.x >= 0 &&
				tile.x < this.numCols &&
				tile.y >= 0 &&
				tile.y < this.numRows &&
				!m_tilesInsideness[tile.y][tile.x]
			)
			{
				m_tilesInsideness[tile.y][tile.x] = true;
				
				if (!tile.equals(this.getEntityPosition(EntityType.EXIT)))
				{
					MoveType.vector.forEach
					(
						function(moveType:MoveType, index:int, vector:Vector.<MoveType>):void
						{
							if (isMoveOpen(tile.x, tile.y, moveType))
							{
								buildTileInsidenessVisit(tile.addXy(moveType.offsetX, moveType.offsetY));
							}
						}
					);
				}
			}
		}
	}
}
