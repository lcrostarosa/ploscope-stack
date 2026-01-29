import React from 'react';

interface SearchIconProps {
  className?: string;
  width?: number | string;
  height?: number | string;
}

const SearchIcon: React.FC<SearchIconProps> = ({
  className,
  width = 24,
  height = 24,
}) => {
  return (
    <svg
      className={className}
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
      width={width}
      height={height}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
      />
    </svg>
  );
};

export default SearchIcon;
